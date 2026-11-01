"""Renders the app's voice clips (DESIGN §3.7, ADR-020).

Reads the spoken texts exported by `flutter test tool/tts/export_texts_test.dart`
and the voice per language from tool/tts/voices.json. Writes MP3 clips to
assets/audio/<lang>/ and assets/audio/manifest.json.

Only clips whose text or voice changed are rendered, so a typo fix re-renders
one clip instead of a whole language.

  python tool/tts/render.py --check            # list stale languages, render nothing
  python tool/tts/render.py --langs en,es      # render stale clips of en and es
  python tool/tts/render.py                    # render every stale clip
  python tool/tts/render.py --get-kokoro       # download the Kokoro files and check them

The engines' downloads are pinned in tool/tts/models.json (ADR-041): the Kokoro
files by SHA-256, the Kyutai weights and voice by Hugging Face commit.

Engines are imported lazily. The packages are pinned with hashes in
tool/tts/requirements/: base.txt for every run, kokoro.txt for Kokoro,
torch.txt then kyutai.txt for Kyutai.
"""
import argparse
import hashlib
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEXTS = ROOT / "build/tts/texts.json"
VOICES = ROOT / "tool/tts/voices.json"
MODELS = ROOT / "tool/tts/models.json"
AUDIO = ROOT / "assets/audio"
MANIFEST = AUDIO / "manifest.json"

PEAK = 0.9  # normalise every clip to the same loudness
MP3_KBPS = 48  # mono speech: small and clear


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def load_json(path: Path, default):
    return json.loads(path.read_text("utf-8")) if path.exists() else default


def stale_clips(lang, texts, voice, manifest):
    """Clip ids of [lang] whose recording is missing or out of date."""
    entry = manifest.get("languages", {}).get(lang, {})
    clips = entry.get("clips", {}) if entry.get("voice") == voice["id"] else {}
    return [
        clip_id
        for clip_id, text in texts.items()
        if clip_id not in clips
        or clips[clip_id]["sha256"] != sha256(text)
        or not (AUDIO / lang / clips[clip_id]["file"]).exists()
    ]


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def kokoro_files(models_dir: str, download: bool = False):
    """Paths of the Kokoro files, each checked against its pinned SHA-256.
    With [download], a missing or wrong file is fetched again first."""
    pinned = load_json(MODELS, {})["kokoro"]
    paths = []
    for name, expected in pinned["files"].items():
        path = Path(models_dir) / name
        if download and (not path.exists() or file_sha256(path) != expected):
            path.parent.mkdir(parents=True, exist_ok=True)
            print(f"Downloading {name}", flush=True)
            urllib.request.urlretrieve(pinned["url"] + name, path)
        if not path.exists():
            sys.exit(f"{path} is missing: run `python tool/tts/render.py --get-kokoro`")
        actual = file_sha256(path)
        if actual != expected:
            sys.exit(f"{path} has SHA-256 {actual}, expected {expected} (tool/tts/models.json)")
        paths.append(str(path))
    return paths


class Kokoro:
    def __init__(self, models_dir: str):
        import espeakng_loader
        from kokoro_onnx import Kokoro as Engine
        from kokoro_onnx.config import EspeakConfig

        # espeak-ng keeps its data path in a 160-byte buffer: allow a short
        # override (a symlink) when the venv path is long.
        data = os.environ.get("ESPEAK_DATA_DIR", espeakng_loader.get_data_path())
        os.environ["ESPEAK_DATA_PATH"] = data
        model, voices = kokoro_files(models_dir)
        self.engine = Engine(
            model,
            voices,
            espeak_config=EspeakConfig(lib_path=espeakng_loader.get_library_path(), data_path=data),
        )

    def render(self, text, voice):
        audio, sr = self.engine.create(text, voice=voice["voice"], speed=voice["speed"], lang=voice["lang"])
        return audio, sr


# Speaking-rate bounds (characters per second) for a plausible recording.
# Outside them a clip was cut short, skipped words or trailed into noise.
MIN_RATE, MAX_RATE = 8.0, 32.0


def plausible(text: str, seconds: float) -> bool:
    return MIN_RATE <= len(text) / max(seconds, 0.01) <= MAX_RATE


def trim(audio, sr, threshold=0.01, keep_s=0.08):
    """Removes leading and trailing near-silence, keeping a short margin."""
    import numpy as np

    loud = np.flatnonzero(np.abs(audio) > threshold * max(float(np.max(np.abs(audio))), 1e-6))
    if loud.size == 0:
        return audio
    keep = int(keep_s * sr)
    return audio[max(loud[0] - keep, 0) : loud[-1] + keep]


class Kyutai:
    """Kyutai TTS 1.6B (en/fr) on CPU, conditioned on a native speaker's voice
    embedding. Sampling is seeded per attempt; an implausible take is retried."""

    ATTEMPTS = 4

    def __init__(self):
        import torch
        from moshi.models.loaders import CheckpointInfo
        from moshi.models.tts import TTSModel

        pinned = load_json(MODELS, {})["kyutai"]
        self.voices = pinned["voices"]
        torch.set_num_threads(os.cpu_count() or 4)
        self.model = TTSModel.from_checkpoint_info(
            CheckpointInfo.from_hf_repo(pinned["model"]["repo"], revision=pinned["model"]["revision"]),
            voice_repo=self.voices["repo"], n_q=32, temp=0.6, device="cpu", dtype=torch.float32)

    def _voice_path(self, name):
        """The speaker embedding, at the pinned commit of the voice repository."""
        from huggingface_hub import hf_hub_download

        return Path(hf_hub_download(self.voices["repo"], name + self.model.voice_suffix,
                                    revision=self.voices["revision"]))

    def _take(self, text, voice):
        import numpy as np
        import torch

        model = self.model
        cond = model.make_condition_attributes([self._voice_path(voice["voice"])], cfg_coef=2.0)
        result = model.generate([model.prepare_script([text], padding_between=1)], [cond])
        with model.mimi.streaming(1), torch.no_grad():
            frames = [model.mimi.decode(f[:, 1:, :]).cpu().numpy()[0, 0] for f in result.frames[model.delay_steps :]]
        return trim(np.clip(np.concatenate(frames), -1, 1), model.mimi.sample_rate)

    def render(self, text, voice):
        import torch

        sr = self.model.mimi.sample_rate
        for attempt in range(self.ATTEMPTS):
            torch.manual_seed(voice["seed"] + attempt)  # deterministic per attempt
            audio = self._take(text, voice)
            if plausible(text, len(audio) / sr):
                return audio, sr
            print(f"  retry {attempt + 1}: implausible length for {text[:40]!r}", flush=True)
        raise RuntimeError(f"no plausible recording after {self.ATTEMPTS} attempts: {text!r}")


def encode_mp3(audio, sr) -> bytes:
    import lameenc
    import numpy as np

    peak = float(np.max(np.abs(audio))) or 1.0
    pcm = (audio / peak * PEAK * 32767).astype("<i2")
    encoder = lameenc.Encoder()
    encoder.set_bit_rate(MP3_KBPS)
    encoder.set_in_sample_rate(sr)
    encoder.set_channels(1)
    encoder.set_quality(2)
    return encoder.encode(pcm.tobytes()) + encoder.flush()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="print stale languages as JSON and exit")
    parser.add_argument("--langs", default="", help="comma-separated languages (default: all)")
    parser.add_argument("--models", default=os.environ.get("KOKORO_MODELS", "build/tts/models"))
    parser.add_argument("--get-kokoro", action="store_true", help="download and check the Kokoro files, then exit")
    args = parser.parse_args()
    if args.get_kokoro:
        kokoro_files(args.models, download=True)
        return

    texts = load_json(TEXTS, None)
    if texts is None:
        sys.exit(f"{TEXTS} is missing: run `flutter test tool/tts/export_texts_test.dart` first")
    voices = {k: v for k, v in load_json(VOICES, {}).items() if not k.startswith("_")}
    manifest = load_json(MANIFEST, {"languages": {}})
    langs = [l for l in (args.langs.split(",") if args.langs else voices) if l in voices]

    stale = {lang: stale_clips(lang, texts[lang], voices[lang], manifest) for lang in langs}
    if args.check:
        print(json.dumps({
            "languages": [l for l, ids in stale.items() if ids],
            "engines": sorted({voices[l]["engine"] for l, ids in stale.items() if ids}),
        }))
        return

    engines = {}
    for lang in langs:
        voice = voices[lang]
        entry = manifest["languages"].get(lang, {})
        if entry.get("voice") != voice["id"]:
            entry = {"voice": voice["id"], "clips": {}}
        clips = entry["clips"]
        out_dir = AUDIO / lang
        out_dir.mkdir(parents=True, exist_ok=True)

        for i, clip_id in enumerate(stale[lang], 1):
            if voice["engine"] not in engines:
                engines[voice["engine"]] = Kokoro(args.models) if voice["engine"] == "kokoro" else Kyutai()
            text = texts[lang][clip_id]
            audio, sr = engines[voice["engine"]].render(text, voice)
            (out_dir / f"{clip_id}.mp3").write_bytes(encode_mp3(audio, sr))
            clips[clip_id] = {"file": f"{clip_id}.mp3", "sha256": sha256(text), "ms": round(len(audio) / sr * 1000)}
            print(f"[{lang} {i}/{len(stale[lang])}] {clip_id} ({len(audio) / sr:.1f}s)", flush=True)

        # Forget clips whose text no longer exists.
        for clip_id in [c for c in clips if c not in texts[lang]]:
            (out_dir / clips.pop(clip_id)["file"]).unlink(missing_ok=True)
        entry["clips"] = dict(sorted(clips.items()))
        manifest["languages"][lang] = entry
        # Saved after each language, so a long run keeps what it finished.
        manifest["languages"] = dict(sorted(manifest["languages"].items()))
        MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", "utf-8")


if __name__ == "__main__":
    main()

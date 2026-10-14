"""Renders the app's voice clips (DESIGN §3.7, ADR-020).

Reads the spoken texts exported by `flutter test tool/tts/export_texts_test.dart`
and the voice per language from tool/tts/voices.json. Writes MP3 clips to
assets/audio/<lang>/ and assets/audio/manifest.json.

Only clips whose text or voice changed are rendered, so a typo fix re-renders
one clip instead of a whole language.

  python tool/tts/render.py --check            # list stale languages, render nothing
  python tool/tts/render.py --langs en,es      # render stale clips of en and es
  python tool/tts/render.py                    # render every stale clip

Engines are imported lazily: Kokoro needs `kokoro-onnx`, Chatterbox needs
`chatterbox-tts` (PyTorch). Both need `lameenc`, `numpy` and `soundfile`.
"""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEXTS = ROOT / "build/tts/texts.json"
VOICES = ROOT / "tool/tts/voices.json"
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


class Kokoro:
    def __init__(self, models_dir: str):
        import espeakng_loader
        from kokoro_onnx import Kokoro as Engine
        from kokoro_onnx.config import EspeakConfig

        # espeak-ng keeps its data path in a 160-byte buffer: allow a short
        # override (a symlink) when the venv path is long.
        data = os.environ.get("ESPEAK_DATA_DIR", espeakng_loader.get_data_path())
        os.environ["ESPEAK_DATA_PATH"] = data
        self.engine = Engine(
            f"{models_dir}/kokoro-v1.0.onnx",
            f"{models_dir}/voices-v1.0.bin",
            espeak_config=EspeakConfig(lib_path=espeakng_loader.get_library_path(), data_path=data),
        )

    def render(self, text, voice):
        audio, sr = self.engine.create(text, voice=voice["voice"], speed=voice["speed"], lang=voice["lang"])
        return audio, sr


class Chatterbox:
    def __init__(self):
        from chatterbox.mtl_tts import ChatterboxMultilingualTTS

        self.model = ChatterboxMultilingualTTS.from_pretrained(device="cpu")

    def render(self, text, voice):
        import torch

        torch.manual_seed(voice["seed"])  # same text + seed → same recording
        wav = self.model.generate(text, language_id=voice["language_id"])
        return wav.squeeze(0).numpy(), self.model.sr


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
    args = parser.parse_args()

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
                engines[voice["engine"]] = Kokoro(args.models) if voice["engine"] == "kokoro" else Chatterbox()
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

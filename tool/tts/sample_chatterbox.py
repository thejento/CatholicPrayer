"""Renders Hail Mary samples with Chatterbox Multilingual (MIT) for voice
selection (design phase of backlog F-08). Runs in GitHub Actions.

Usage: python sample_chatterbox.py <repo_root> <out_dir>
"""
import json
import sys
import time

import torchaudio
from chatterbox.mtl_tts import ChatterboxMultilingualTTS

repo, out = sys.argv[1:3]
model = ChatterboxMultilingualTTS.from_pretrained(device="cpu")

# Two settings: library defaults, and a calmer, slower delivery for prayer.
settings = {"default": {}, "calm": {"exaggeration": 0.3, "cfg_weight": 0.3}}
for lang in ("en", "es", "fr"):
    prayers = json.load(open(f"{repo}/assets/data/prayers/{lang}.json"))["prayers"]
    text = next(p["text"] for p in prayers if p["id"] == "hail_mary")
    for name, kwargs in settings.items():
        start = time.time()
        wav = model.generate(text, language_id=lang, **kwargs)
        path = f"{out}/chatterbox_{lang}_{name}.wav"
        torchaudio.save(path, wav, model.sr)
        seconds = wav.shape[-1] / model.sr
        print(f"{lang} {name}: {seconds:.1f}s audio in {time.time() - start:.0f}s", flush=True)

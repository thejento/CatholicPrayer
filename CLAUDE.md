# CLAUDE.md

Guide for Claude sessions on **Rosary Companion** (`thejento/CatholicPrayer`): a Flutter app
that guides newcomers through the Catholic Rosary, one bead at a time. Android phones and
tablets, Android TV (D-pad) and the web, from one codebase. Offline, no account, no tracking.
App id `com.catholicrosarycompanion.crc`, package name `crc`, version in `pubspec.yaml`.

- Web app (deployed from `main`): https://thejento.github.io/CatholicPrayer/
- Design: `docs/DESIGN.md` · Decisions: `docs/DECISIONS.md` (ADR-001…028) · History: `BACKLOG.md`
- **Open work: GitHub Issues**, see "Backlog and issues" below.

## How the owner works

- **The owner merges every PR.** Claude branches from `main`, opens the PR **against `main`**
  (never stack PRs on feature branches: they once merged into the branch instead of `main`),
  waits for CI, then reports. If a PR is still open and new work touches the same code, add
  commits to that PR instead of opening a second one.
- **Design-first:** each feature updates `docs/DESIGN.md` (a §3.x section), an ADR in
  `docs/DECISIONS.md` when a real choice was made, and `BACKLOG.md` / the issue.
- **Content must be public domain** (or openly licensed, with credits on the licence page):
  prayers, Bible translations, paintings (CC0 museum releases only), voices. The owner
  insisted: "Stick to public domain text". Write long texts in small pieces, one language file
  at a time; if a write is blocked by content limits, skip that text and say so.
- Three languages everywhere: **en, es, fr**. UI strings in `lib/src/l10n/app_<lang>.arb`
  (run `flutter gen-l10n`), content in `assets/data/**/<lang>.json`. Parity tests fail if one
  is missing. Use gender-neutral wording in es/fr ("cuando quiera", "quand vous le souhaitez").
- The owner reads the answers in plain language: explain what changed for the person praying,
  then the technical detail.

## Toolchain

- Flutter **3.47.7**, pinned in `pubspec.yaml` (`environment.flutter`); CI reads it from there.
  The user's `~/bin/flutter` is an older 3.35: **don't use it or touch it**. Install 3.47.7 in
  the session scratchpad if needed and put its `bin` first on `PATH`.
- Python tools in `tool/` (TTS rendering, scripture build, artwork, saint links). Run them in
  a venv in the scratchpad.

```bash
flutter pub get && flutter gen-l10n
dart format lib test integration_test          # CI: --output=none --set-exit-if-changed
flutter analyze --fatal-infos
flutter test --coverage && scripts/check_coverage.sh 90
flutter test --update-goldens test/goldens     # after an intentional UI change; look at the PNGs
flutter test tool/render_icons_test.dart       # icons and store graphics are drawn in code
```

On-device tests (`integration_test/`, real audio player):

```bash
flutter test integration_test -d <android-device>
chromedriver --port=4444 &                     # matching Chrome version
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/clip_player_test.dart -d web-server --browser-name=chrome \
  --headless --web-browser-flag=--autoplay-policy=no-user-gesture-required
```

## Architecture (`lib/src/`)

| Folder | What lives there |
|---|---|
| `domain/` | Pure Dart, no Flutter: 80-step sequence and bead map (`rosary_sequence`), `rosary_session`, weekday/Sunday mysteries, step guidance, liturgical calendar (Easter computus, seasons, colours), General Roman Calendar with ranks, precedence and transfers (`sanctoral`), injectable `Clock` |
| `data/` | Asset repositories (content, scripture, saints, art), `PreferencesStore`, `DeviceProfile` (TV / Android / web), `LinkOpener`, Vatican News saint links, licence registration |
| `providers/` | `ChangeNotifier`s: theme, settings (voice, auto-advance, auto-scroll…), saved session |
| `audio/` | `clips.dart` (clip ids per step), `AudioCatalog`, `ClipPlayer` (just_audio), `VoiceGuide` (follows the session, auto-advance, reading time for auto-scroll) |
| `reminders/` | Daily reminder: weekly local notifications, Android phones only |
| `ui/` | Screens (home, rosary, picker, library, scripture, about today, settings) and widgets (beads painter, saint sheet, web footer) |
| `app_info.dart` | Version (`APP_VERSION` / `APP_BUILD` dart-defines), Play and Issues URLs, `playStoreListed` switch |

- State: `provider` + `ChangeNotifier`. Dependencies come through constructors and Provider so
  tests pass fakes: `test/helpers/test_app.dart` (`TestApp`: fixed clock, in-memory prefs,
  `FakeClipPlayer`, recorded links, `isAndroid` / `isTelevision` flags).
- Themes: classic and kid-friendly. Paintings appear only in classic.
- Assets: `assets/data/` (prayers, mysteries, scripture, saints, art.json), `assets/audio/<lang>/`
  (pre-rendered voice), `assets/art/` (WebP paintings).

## Tests and quality gates (CI, all required)

Format, analyze (infos fatal), unit + widget + content-parity tests, goldens (2 themes ×
phone/tablet/TV), accessibility on every screen (`meetsGuideline`: tap targets, labels,
contrast, 200 % text without overflow), coverage ≥ 90 % (`scripts/check_coverage.sh`,
generated code excluded), web and APK builds.

Test tips:
- Lists only build what is visible: use a tall view (`tester.view.physicalSize`), or pass
  `scrollable:` to `scrollUntilVisible` when there are several scrollables, or `ensureVisible`.
- For a bug fix, check that the new test fails without the fix.

## Voice: how the recordings are made (the recipe that worked)

Every spoken word is known in advance, so the voice is **pre-rendered at build time** to MP3
clips and shipped in `assets/audio/<lang>/` with a hash manifest (ADR-020, ADR-021). Nothing is
synthesised on the device. Finding usable voices took several rounds; keep this recipe.

**Voices** (`tool/tts/voices.json`, the single source; changing an entry's `id` re-renders
that whole language):

| Lang | Engine | Voice | Settings |
|---|---|---|---|
| en | Kokoro v1.0 (`kokoro-onnx`, Apache-2.0) | `af_bella` | `lang: en-us`, speed 0.9 |
| es | Kokoro v1.0 | `ef_dora` | `lang: es`, speed 0.9 |
| fr | Kyutai TTS 1.6B en/fr (`moshi`, CC BY 4.0) | reader **K2** = `cml-tts/fr/7400_2928_000100-0001_enhanced.wav` (LibriVox, CC BY 4.0) | seed 42, `temp=0.6`, `cfg_coef=2.0`, `n_q=32`, CPU float32 |

**What failed, so don't retry it:**
- **Chatterbox** French built-in voice: strong English accent and frequent glitches.
  Chatterbox cloning a native reader would fix the accent but not the glitch risk. Removed.
- **Blending Bella into es/fr** (Kokoro voice mixing): kept an English accent.
- **Kokoro French (Siwis):** rejected by ear. **Piper:** steady but flat, and some voices have
  research-only dataset licences.
- Non-commercial models (Coqui XTTS-v2, Fish Audio, Voxtral) can't be used.
- On-device `flutter_tts`: quality varies too much (TV, web).

**Pipeline:**
1. Spoken texts come from the app's own code: `speakableTexts()` in `lib/src/audio/clips.dart`
   (prayers with V./R. markers dropped, mystery announcements, guidance lines from the ARB
   files). `flutter test tool/tts/export_texts_test.dart` writes `build/tts/texts.json`.
2. `python tool/tts/render.py [--check] [--langs fr]` renders **only stale clips** (missing
   file, changed text hash, or changed voice id). It writes `assets/audio/<lang>/<clip>.mp3`
   and `assets/audio/manifest.json` (sha256 + ms per clip), saving after each language.
3. Post-processing for every clip: trim leading/trailing silence (keep 80 ms), normalise the
   peak to 0.9, mono MP3 at 48 kbps.
4. **Kyutai safeguards:** render each clip **whole** (don't split it into sentences). Seed it
   `seed + attempt`, and retry (up to 4 takes) when the speaking rate is implausible
   (outside 8–32 characters per second: cut short, skipped words, or babble).
5. A freshness test in CI (`test/data/audio_manifest_test.dart`) fails when a clip is stale. **`render-audio.yml`** does the rendering
   on any branch push that changes spoken text (`assets/data/**`, ARB files, `clips.dart`,
   `tool/tts/**`). It installs only the engines needed (Kokoro model files cached from the
   kokoro-onnx GitHub release; `pip install moshi` with CPU-only PyTorch from
   `download.pytorch.org/whl/cpu`, HF cache for weights). It commits the clips to the branch
   and approves the bot-triggered CI run. Kokoro takes minutes; **French (Kyutai) takes about
   an hour**, so expect the PR's first CI run to fail on the freshness check until the bot's
   commit lands.

**Running locally:** use a venv in the scratchpad: `pip install kokoro-onnx soundfile lameenc
numpy` (Kokoro models in `build/tts/models/` or `$KOKORO_MODELS`); for French also `pip
install moshi --extra-index-url https://download.pytorch.org/whl/cpu`. espeak-ng keeps its data
path in a 160-byte buffer: if the venv path is long, symlink the data dir and set
`ESPEAK_DATA_DIR`. Prefer letting CI render French.

**Choosing or checking a voice:** Claude can't listen. For each candidate, render the Hail
Mary, a short guidance line (where glitches showed) and the Creed (long text). Transcribe them
with Whisper and compare to the text, which catches dropped words or babble but not accent.
Then publish an audition page (artifact) for the owner to choose **by ear**. After any
re-render, the owner listens once (that was C-04) before it's considered done.

**Fixing a mispronunciation:** change the spelling sent to the voice (the spoken text, not the
displayed text) and let the pipeline re-render just that clip.

**Credits:** CC BY voices and models are credited on the licence page
(`lib/src/audio/voice_licenses.dart`): Kokoro, Kyutai and the CML-TTS reader.

**Playback:**
- Each step plays its instruction clip (`guide_*`), then its prayer or mystery clip. Speed is
  0.75–1.25× through the player, with pitch preserved, so changing speed needs no re-render.
- **Web gotcha:** a just_audio player that has finished one clip can't start another in the
  browser (it replays the first). `JustAudioClipPlayer` uses a **fresh player per clip**.
  Don't "optimise" this back to one player or a playlist. `integration_test/clip_player_test.dart`
  guards it in Chrome and on Android.
- Auto-advance waits on mystery announcements until the passages are read aloud (issue F-18,
  `VoiceGuide.waitsHere`). Auto-scroll follows the prayer clip's length (`VoiceGuide.reading`).

## CI/CD and release

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yml` | PR, push to `main` | checks: "Format · Analyze · Test", "Build web", "Build Android APK" |
| `deploy-web.yml` | push to `main` | GitHub Pages, with `APP_BUILD` = short commit |
| `render-audio.yml` | branch push touching spoken text | renders stale clips and commits them |
| `release.yml` | tag `vX.Y.Z` | signed AAB + APK + web zip on a GitHub Release (`APP_VERSION` = tag) |

The signing secrets are set. Play Store publishing is issues O-10/O-11; when the listing is
live, set `playStoreListed = true`.

## Backlog and issues

Open work lives in **GitHub Issues**. Titles start with a stable ID: `F-` feature, `T-` TV,
`W-` web, `Q-` quality, `O-` ops, `C-` content, `I-` idea. New items take the next free number
(see the top of `BACKLOG.md`, and update it). Milestones are iterations; labels give the type,
`owner` (the owner's own tasks) and `on hold`. A PR that completes an item says
`Closes #NN` and adds a line to the done history in `BACKLOG.md`.

## Shell and GitHub gotchas

- `gh pr edit` can fail with a "Projects (classic) is being deprecated" GraphQL error; use
  `gh api -X PATCH repos/thejento/CatholicPrayer/pulls/<n> -f title=… -F body=@file`.
- Wait for CI with an until-loop on `gh pr checks <n>` (no bare `sleep`).
- `pkill -f <pattern>` can match and kill your own shell; kill by PID instead.
- Some museum image hosts block downloads (Art Institute of Chicago: 403). The working ones are
  NGA open data, Cleveland open access and SMK.

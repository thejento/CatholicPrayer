# Catholic Rosary Companion: Design

> Status: **living document**. Change it in the same PR as the code it describes.
> The reasons behind each choice are in [DECISIONS.md](DECISIONS.md). The work queue is in [BACKLOG.md](../BACKLOG.md).

## 1. Purpose

Help **people who are new to the Rosary** pray it from start to finish without
feeling lost. The app tells them what to do and why, one bead at a time:
*hold the crucifix → make the Sign of the Cross → …*.

It is not a reference work. The pace is calm and the screens stay simple, and the
app never asks the user to know anything in advance.

### Personas

| Persona | Context | Needs |
|---|---|---|
| **Newcomer adult** (primary) | Curious, maybe RCIA/OCIA, has never prayed the Rosary | Know *what to say*, *when*, *which bead*, and *why* |
| **Family on the couch** | Praying together in front of an Android TV | Large text readable from 3 m away, a remote control to advance, a kid-friendly theme |
| **Returning Catholic** | Knew it as a child | Today's mysteries, quick start, the guidance can be hidden |
| **Child** | With a parent | Bright theme, big tap targets, simple words |

### Non-goals (for now)

User accounts, cloud sync, analytics, ads, or any network dependency at runtime.
The app works **fully offline** and collects **no personal data**.

## 2. Platforms

| Target | Form factor | Input | Distribution |
|---|---|---|---|
| Android phone/tablet | 360–1280 dp wide | Touch | Google Play (AAB), GitHub Release (APK) |
| Android TV | 960×540 dp, 10-foot UI | D-pad / remote | Same AAB, with a Leanback launcher entry |
| Web | Any width | Mouse, keyboard, touch | GitHub Pages (PWA) |

All three share **one Flutter codebase**. The app adapts to each platform through
layout breakpoints and input handling. There are no per-platform forks.

## 3. User experience

### 3.1 Screen flow

```
                ┌──────────────┐
                │    Home      │  Today: <weekday> → suggested mysteries
                │ [Pray now]   │
                │ [Learn]      │  (Prayer library)
                │ [⚙ Settings] │
                └──┬───┬───┬───┘
        ┌──────────┘   │   └───────────┐
        ▼              ▼               ▼
 ┌─────────────┐ ┌─────────────┐ ┌──────────┐
 │ Mysteries   │ │ Prayer list │ │ Settings │ theme, language,
 │ picker      │ │  → detail   │ │          │ guidance on/off
 └──────┬──────┘ └─────────────┘ └──────────┘
        ▼
 ┌──────────────────────────────────────────┐
 │ Guided Rosary                            │
 │  ┌────────────┐  Step 12 / 80  ▓▓░░░░░   │
 │  │  rosary    │  First Joyful Mystery    │
 │  │  drawing,  │  ── Hail Mary (3 / 10) ──│
 │  │  current   │  "Hail Mary, full of…"   │
 │  │  bead glows│  ℹ Hold the next small   │
 │  └────────────┘    bead and pray…        │
 │     [◀ Back]          [Next ▶]           │
 └──────────────────────────────────────────┘
```

### 3.2 Newcomer guidance (the core feature)

Every step of the Rosary carries three layers of information:

1. **Where am I?** The current bead glows on the rosary drawing. A progress bar
   and a label such as "Third decade · Hail Mary 4 of 10" show the position.
2. **What do I say?** The full prayer text in the chosen language, in large type.
3. **What do I do?** A one-sentence *guidance* line, e.g. "Hold the crucifix and
   make the Sign of the Cross." Experienced users can hide it in Settings.

Mystery announcements show the mystery title, a Scripture reference and its
traditional *fruit* (e.g. "Humility"), so a newcomer has something to meditate on.

When the step changes, a **glow travels** from the bead just prayed to the next
one (about 0.5 s), so the eye follows the movement on the physical rosary.

### 3.2.1 Resume

Progress is saved on every step. If the person leaves mid-Rosary, Home shows a
**"Continue where you left off"** card with the set and step. Finishing the
Rosary or going back to step 1 clears it. A saved step that no longer exists is
clamped to the sequence.

### 3.3 Interaction model

| Action | Touch | Keyboard / Web | TV remote |
|---|---|---|---|
| Next step | Tap *Next* or the glowing bead | `→`, `Space`, `Enter` | D-pad right, Select |
| Previous step | Tap *Back* | `←` | D-pad left |
| Leave | App-bar back | `Esc` | Back |

*Next* has initial focus, so the remote's Select button advances. *Back* is never
disabled, so D-pad focus can't land on a dead control. Focus must always be
visible, which is a hard requirement for TV.

### 3.4 Responsive layout

| Width (logical px) | Layout |
|---|---|
| `< 600` (phone) | Column: small rosary strip on top, text below |
| `600–1199` (tablet/web) | Row: rosary left (40 %), text right |
| `≥ 1200`, or Android TV | Row with a larger type scale (×1.3, the 10-foot UI) |

Android TV is detected through the `crc/device` platform channel (`MainActivity.kt`:
UI mode *television* or the Leanback feature). The web and phones report `false`
(ADR-016).

### 3.5 Themes

* **Classic** is a deep liturgical maroon with muted gold and serif headings.
* **Kid-friendly** is sky blue with sunny orange, rounded shapes and heavier weights.

Both themes must meet WCAG AA contrast for body text.

### 3.6 Languages

English, Spanish and French at launch. Two kinds of text, kept separate:

* **UI strings** live in `lib/src/l10n/*.arb` and use Flutter gen-l10n.
* **Devotional content** (prayers, mysteries) lives in one file per language:
  `assets/data/prayers/<lang>.json` and `assets/data/mysteries/<lang>.json`.
  `ContentRepository` merges them. The fallback order is the requested language, then English,
  then any available language.

Content uses **traditional, public-domain** wordings (ADR-013). Examples are the English
"who art in heaven" forms and the French *vous* forms, not the copyrighted ICEL/AELF
translations. Tests check that every prayer the Rosary needs exists in every
supported language.

### 3.7 Voice (read aloud), see ADR-020

**Goal:** a calm, natural voice that prays along with the user. It must not sound
robotic, must work offline, and must sound the same on phone, TV and web.

**Key idea: pre-recorded, not synthesised on the device.** Every spoken text is
known in advance: the prayers, the mystery announcements and the guidance lines. They
are rendered **once, at build time**, by an open-source neural TTS model and shipped
as small compressed audio files. The app only *plays* audio.

| | Pre-rendered (chosen) | On-device TTS (`flutter_tts`) |
|---|---|---|
| Voice quality | Best available open model, same everywhere | Depends on device; often robotic on TV/web |
| Offline | Yes | Usually; web voices may need network |
| Device cost | Playback only | Engine + voice data per device |
| Size | ≈ 1.8 MB per language (≈ 5 min of speech, MP3 48 kbps) | 0 |
| Text changes | Re-render (automated) | Instant |

**Voices** (chosen by ear in listening tests, see ADR-020 and ADR-021):

| Language | Engine | Voice |
|---|---|---|
| English | Kokoro-82M | Bella (`af_bella`), speed 0.9 |
| Spanish | Kokoro-82M | Dora (`ef_dora`), speed 0.9 |
| French | Kyutai TTS 1.6B (en/fr) | native reader `cml-tts/fr/7400_2928_000100-0001_enhanced`, seed 42 |

The mapping lives in `tool/tts/voices.json`. Changing an entry re-renders that language.

**What is spoken** (44 clips per language):

* every prayer (8 clips)
* each mystery announcement, composed as
  `"{Set}. {Ordinal} mystery: {Title}."`, e.g. *"Joyful Mysteries. First mystery: The
  Annunciation."* (20 clips)
* the guidance line of each of the 16 kinds of step, with a setting to turn it off

**Pipeline**

```
assets/data/**.json + app_*.arb
   │  flutter test tool/tts/export_texts_test.dart   (texts come from the app's own code)
   ▼
build/tts/texts.json ──► tool/tts/render.py ──► assets/audio/<lang>/<clip>.mp3
                         (only stale clips)     assets/audio/manifest.json
                                                (voice id; clip → sha256(text), duration)
```

* A content test fails CI when a clip is **missing or stale**, meaning its text hash no longer
  matches the current text. So the audio can never silently drift from the words on screen.
* `render-audio.yml` runs on any branch push that changes spoken text. It renders only
  the stale clips, installs only the engines needed (Kokoro takes minutes; Kyutai
  takes about an hour for French on CPU) and commits them to the branch. GitHub holds CI runs
  triggered by a bot push for approval, and branch protection only counts PR-event runs,
  so the job approves that held run through the API.
* Kokoro (EN/ES) can also be rendered locally in about 2 minutes.

**Playback** (`just_audio`, MIT, Android + web)

* A speaker toggle in the Rosary app bar starts and stops the voice. The choice is persisted.
  On a TV remote or keyboard, the **play/pause** key does the same.
* While the voice is on, a bar under the prayer offers **speed** (− / + in steps of
  0.75×, 0.85×, 1.0×, 1.15×, 1.25×) and an **auto-advance** chip. The speed changes playback
  only, with pitch preserved by ExoPlayer and the browser, so no re-render is needed.
* Settings → Voice: read aloud, read the guidance aloud, auto-advance, and the pause
  before the next prayer (1–5 s). *About and credits* opens the licence page, which carries
  the required voice attributions.
* A language without recordings shows no speaker button, and Settings explains why.
* **Next** or a D-pad move stops the current clip and plays the new step's clip.
* **Auto-advance** (off by default): when a clip ends, wait for the pause (1–5 s, default
  2 s), then go to the next step. The person can then simply listen and pray along.
* The Hail Mary is a single clip reused 53 times. Variants are a later idea.

### 3.8 Daily reminder (F-12), see ADR-023

A gentle nudge to build the habit, **Android phones and tablets only** (not TV, where
notifications are not part of the experience, and not the web, where a page cannot
notify once it is closed).

* Settings → **Daily reminder**: a switch (off by default) and a time (default 20:00),
  picked with the system time picker.
* Turning it on asks for the notification permission (Android 13+). If the person refuses,
  the switch stays off and a message explains how to allow notifications in Android settings.
* The notification names that day's mysteries, so seven weekly reminders are scheduled,
  one per weekday: *"Time to pray the Rosary"* / *"Today: the Sorrowful Mysteries."*
* Texts follow the app language. Reminders are rescheduled at start-up and whenever the
  language, time or switch changes, so they never go stale; Android restores them after a
  reboot or app update.
* Delivery is *inexact* (Android may shift it by a few minutes to save battery), so the app
  needs no exact-alarm permission.
* Tapping the notification opens the app on Home, where today's mysteries and any
  unfinished Rosary are waiting.

### 3.9 Bible passage of each mystery (F-17), see ADR-024

Each mystery announcement has a **Read the passage** button under its Scripture reference.
It opens the full passage (for example Luke 1:26-38 for the Annunciation), with verse numbers
and the translation's credit at the bottom, so the person can read it before meditating.

| Language | Translation | Licence |
|---|---|---|
| English | Douay-Rheims, 1899 American Edition (Catholic) | public domain |
| Spanish | Torres Amat, 1836 edition (Catholic), spelling modernized | public domain |
| French | Sainte Bible néo-Crampon Libre (Catholic, © 2022 Fraternité de Tibériade) | CC BY-SA 4.0 |

* All three say "full of grace" / "llena de gracia" / "pleine de grâce" at Luke 1:28, the words of
  the Hail Mary.
* The Assumption is not narrated in Scripture; like the Coronation it shows Revelation 12:1,
  the passage Tradition reads for it.
* `tool/scripture/build.py` downloads the sources and writes `assets/data/scripture/<lang>.json`
  (20 passages, 178 verses). The Spanish spelling update (accents, j/g, modern names such as
  Jerusalén and Belén) is an explicit list in `tool/scripture/modern_es.py`; the wording is unchanged.
* On TV the D-pad moves from verse to verse, scrolling as it goes.
* Read aloud: not yet (backlog F-18).

## 4. The Rosary model

### 4.1 Sequence (80 steps)

```
Intro (7):    Sign of the Cross · Apostles' Creed · Our Father ·
              Hail Mary ×3 (faith, hope, charity) · Glory Be
Decade ×5 (14 each = 70):
              Announce mystery · Our Father · Hail Mary ×10 ·
              Glory Be · Fatima Prayer
Closing (3):  Hail, Holy Queen · Closing prayer · Sign of the Cross
```

Totals: 53 Hail Marys, 6 Our Fathers and 6 Glory Bes.

### 4.2 Physical rosary → bead indices

```
 index  0      1     2 3 4     5       6        7..16   17   18..27  28 ...  50   51..60
       ✝︎   ──  ● ──  ○○○  ──  ●  ──  [medal] ── ○×10 ── ● ── ○×10 ── ● ...  ● ── ○×10 ─┐
     crucifix                                  decade 1  OF2  decade 2       OF5  decade 5│
                                     ▲────────────────────────────────────────────────────┘
```

* The intro Glory Be, the first announcement and the first decade's Our Father
  are all said on the large bead `5`. That follows the usual "on the next large bead" instruction.
* After a decade, the Glory Be and Fatima Prayer move to the **next** large bead
  (or to the medal after the fifth decade). This tells the newcomer that the decade is finished.
* Hail, Holy Queen and the closing prayer are on the medal (`6`). The final Sign of the
  Cross returns to the crucifix (`0`).

### 4.3 Mysteries by weekday

| Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|---|---|---|---|---|---|---|
| Joyful | Sorrowful | Glorious | Luminous | Sorrowful | Joyful | Glorious |

The user can always pick another set before starting. Liturgical-season
overrides (e.g. Sorrowful on Lent Sundays) are in the backlog.

## 5. Architecture

```
lib/
  main.dart                 bootstrap: load prefs + content, then runApp
  src/
    app.dart                MaterialApp, theme, locale, routes, Shortcuts
    domain/                 pure Dart, no Flutter imports → fast unit tests
      mysteries.dart        MysterySet, Mystery, weekday suggestion
      rosary_sequence.dart  RosaryStep, buildRosarySequence()
      rosary_session.dart   ChangeNotifier: index, next/previous, progress
      clock.dart            injectable time source
    models/prayer.dart      localized prayer value object
    data/content_repository.dart  merges assets/data/{prayers,mysteries}/<lang>.json
    data/preferences_store.dart   key/value interface (+ in-memory fake)
    data/device_profile.dart      TV detection via platform channel
    providers/
      theme_manager.dart    theme, persisted
      settings_controller.dart  locale + guidance toggle, persisted
      saved_session_controller.dart  unfinished Rosary, persisted
    ui/
      screens/              home, prayer_library, prayer_detail,
                            mystery_picker, rosary, settings
      widgets/              rosary_beads (CustomPainter), step_panel, …
```

* **State management** uses `provider` with `ChangeNotifier`. The domain layer has no
  dependency on Flutter, so its logic is tested in plain unit tests.
* **Persistence** uses `shared_preferences` (`SharedPreferencesAsync`) behind a
  `PreferencesStore` interface. It works on Android and web with no account.
* **Dependency injection** goes through constructor parameters. Tests pass fakes, such as an
  in-memory preferences store and an injected clock (`DateTime Function()`).

## 6. Quality strategy

| Layer | Tool | Gate in CI |
|---|---|---|
| Format | `dart format --set-exit-if-changed` | required |
| Static analysis | `flutter analyze` (flutter_lints + stricter rules) | required, infos are fatal |
| Unit (domain, models, data) | `flutter test` | required |
| Widget (screens, keyboard/D-pad) | `flutter test` | required |
| Content integrity (JSON/ARB parity) | `flutter test` | required |
| Coverage | `scripts/check_coverage.sh`, generated code excluded | required (≥ 90 %) |
| Builds | `flutter build web`, `flutter build apk` | required |
| Golden screenshots (2 themes × phone/tablet/TV) | `matchesGoldenFile`, 0.5 % tolerance | required |
| Accessibility (every screen, both themes; 200 % text on phone, sideways phone, TV) | `meetsGuideline` tap-target, label, contrast; overflow check | required |
| Device/integration | `integration_test` on an emulator | backlog |

## 7. Delivery pipeline (CI/CD)

```
 PR / push ──► ci.yml ─┬─ quality: format · analyze · test · coverage gate
                       ├─ build-web  (artifact)
                       └─ build-android (debug-signed APK artifact)

 push main ──► deploy-web.yml ─► flutter build web --base-href /CatholicPrayer/
                                ─► GitHub Pages

 tag vX.Y.Z ─► release.yml ─► signed AAB + APK (keystore from secrets)
                             ─► GitHub Release with assets
                             ─► (backlog) Google Play internal track
```

* **Toolchain pin:** the Flutter version is pinned in `pubspec.yaml`
  (`environment.flutter`). CI reads it from there (`flutter-version-file`), so
  local builds and CI use the same version.
* **Branching:** trunk-based. `main` is protected and changes arrive through short-lived PRs.
* **Versioning:** SemVer tags `vX.Y.Z`. The Android `versionCode` comes from
  `github.run_number` during releases.
* **Secrets** (repository → Settings → Secrets → Actions):
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD`. Without them, a release falls back to debug signing
  and the release is labelled *pre-release*.
* **Dependencies:** Dependabot opens weekly PRs for pub, Gradle and Actions.

## 8. Brand assets

App icons (Android mipmaps, web, maskable, favicon), the Android TV banner and the
Play Store icon and feature graphic are **drawn in code** by
`tool/render_icons_test.dart`. The emblem is a gold rosary on a liturgical-maroon gradient.
Regenerate with `flutter test tool/render_icons_test.dart` (ADR-017).

## 9. Privacy & accessibility

* No network calls and no analytics. Android permissions, all normal (none grant access
  to personal data):
  * `POST_NOTIFICATIONS`: the optional daily reminder; asked for only when it is turned on.
  * `RECEIVE_BOOT_COMPLETED`, `VIBRATE`: restore the reminder after a reboot, vibrate with it.
  * `ACCESS_NETWORK_STATE`: added by the audio player library (ExoPlayer); the app plays
    bundled files only.
* Screen readers (TalkBack, browser readers): the rosary drawing is one labelled button
  ("Rosary, bead 14 of 61") whose tap moves to the next step. The step title is a heading
  and a live region, so each new step is announced without moving focus. The progress
  bar is labelled "Rosary progress". Decorative icons are silent.
* The app respects the system text scale with no cap; layouts are checked at 200 %.
  Every tap target is at least 48 dp, and text meets WCAG AA contrast in both themes.
* All of this is enforced by `test/ui/accessibility_test.dart` (ADR-022).

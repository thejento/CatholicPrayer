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

* No network calls, no analytics and no permissions in v1. Notifications will add
  `POST_NOTIFICATIONS` later.
* `Semantics` labels on the rosary drawing ("Bead 14 of 59, current"). The app respects
  the system text scale, and every target is at least 48 dp.

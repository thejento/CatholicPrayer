# Rosary Companion

A gentle guide for **people who are new to the Catholic Rosary**. It shows you
which bead you are on, which prayer to say and what to do next, one step at a time.

Runs on **Android phones and tablets**, **Android TV** (D-pad remote) and the
**web**, all from a single Flutter codebase. Fully offline, no account, no tracking.

| | |
|---|---|
| Design | [docs/DESIGN.md](docs/DESIGN.md) |
| Decision log | [docs/DECISIONS.md](docs/DECISIONS.md) |
| Backlog | [BACKLOG.md](BACKLOG.md) |

## Features

- Guided 80-step Rosary with a drawing of the rosary and the current bead highlighted
- A "what to do" guidance line on every step (can be turned off)
- Today's mysteries suggested automatically (Sundays follow Advent and Lent), with the day of the Church year and the saint of the day shown on Home
- Mystery announcements with the fruit of the mystery and its full Bible passage (Douay-Rheims, Torres Amat, néo-Crampon)
- An optional daily reminder naming the day's mysteries (Android)
- A natural voice reads the Rosary aloud (open-source Kokoro / Kyutai, pre-recorded), with adjustable speed and auto-advance
- Resume an unfinished Rosary from the home screen
- Prayer library: the prayers of the Rosary and other traditional prayers (Memorare, St Michael, Angelus, Regina Caeli…)
- English, Spanish and French, with traditional public-domain texts
- Classic and Kid-friendly themes
- Keyboard and TV remote: `←`/`→` to move, `Enter`/Select for Next

## Develop

The Flutter version is pinned in `pubspec.yaml` (`environment.flutter`).

```bash
flutter pub get
flutter run -d chrome                # web
flutter run -d <android-device>      # phone or TV emulator
```

Run the same checks as CI before pushing:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage && scripts/check_coverage.sh 90
```

After an intentional UI change, refresh the golden screenshots:
`flutter test --update-goldens test/goldens`. Icons and store graphics are drawn
in code: `flutter test tool/render_icons_test.dart`.

## Content

Prayers and mysteries live in `assets/data/{prayers,mysteries}/<lang>.json`.
UI text lives in `lib/src/l10n/app_<lang>.arb`. Tests fail when a language is
missing a prayer, a mystery or a UI string. To add a language, add the three
files and the language code to `contentLanguages`.

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | PR, push to `main` | format, analyze, tests + goldens, coverage ≥ 90 %, web and APK builds |
| `deploy-web.yml` | push to `main` | publishes the web app to GitHub Pages |
| `render-audio.yml` | branch push changing spoken text | re-records stale voice clips, commits them, re-runs CI |
| `release.yml` | tag `vX.Y.Z` | signed AAB + APK + web zip on a GitHub Release |

To release: `git tag v1.0.0 && git push origin v1.0.0`.

Release signing uses the repository secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.
Without them, the release is debug-signed and marked as a pre-release.

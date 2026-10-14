# Backlog

Ordered by priority, top first. IDs are stable. When an item is done, tick it
and add the PR number. Prefixes: **F** = feature, **T** = TV, **W** = web,
**Q** = quality, **O** = ops/CI/CD, **C** = content.
Design: [docs/DESIGN.md](docs/DESIGN.md) · Decisions: [docs/DECISIONS.md](docs/DECISIONS.md)

## ✅ Iteration 0: Foundation & pipeline

- [x] O-01 Design doc, decision log, backlog
- [x] O-02 Pin Flutter 3.47.7 in `pubspec.yaml`
- [x] O-03 CI workflow: format, analyze, test, coverage gate, web + APK builds
- [x] O-04 CD: GitHub Pages deploy on `main`
- [x] O-05 Release workflow: tag → signed AAB/APK → GitHub Release
- [x] O-06 Dependabot (pub, gradle, actions)
- [x] F-01 Domain: 80-step sequence, bead map, weekday mysteries, session
- [x] C-01 Prayers + 20 mysteries in EN/ES/FR (JSON assets)
- [x] F-02 Home (today's mysteries), prayer library + detail
- [x] F-03 Mystery picker → guided Rosary with step guidance
- [x] F-04 Rosary bead drawing with highlighted current bead
- [x] F-05 Settings: theme, language, guidance toggle (persisted)
- [x] T-01 Android TV manifest (Leanback launcher, banner, no touchscreen)
- [x] T-02 Keyboard/D-pad: ←/→/Enter/Space on the Rosary screen
- [x] Q-01 Unit + widget + content-parity tests (76 tests, ~98 % coverage)
- [x] C-03 Public-domain prayer texts, one file per language (ADR-013)

## 🔜 Iteration 1: Make it ready to share

- [ ] O-07 **Manual:** set GitHub default branch to `main` and protect it (require CI)
- [ ] O-08 **Manual:** enable Pages (Settings → Pages → Source: GitHub Actions)
- [ ] O-09 **Manual:** create the upload keystore and add the 4 `ANDROID_*` secrets
- [ ] F-06 Resume an interrupted Rosary (persist session index + mysteries)
- [ ] F-07 Animated glow moving between beads (2.3.5 in the original spec)
- [ ] Q-02 Golden tests for both themes × phone/tablet/TV sizes
- [ ] Q-03 Raise the coverage gate to 90 %
- [ ] T-04 Detect Android TV (platform channel) to apply the 10-foot type scale
- [ ] C-02 Content review of ES/FR texts by a native speaker / parish
- [ ] W-01 Proper PWA manifest (name, colours, icons) and favicon
- [ ] T-03 Proper 320×180 TV banner artwork

## Iteration 2: Accessibility & audio

- [ ] F-08 Text-to-speech (`flutter_tts`) with language-matched voice
- [ ] F-09 Auto-advance after TTS completion with configurable pause
- [ ] F-10 Semantics audit and TalkBack/screen-reader pass
- [ ] F-11 Large-text mode check (text scale 200 %)

## Iteration 3: Habit & reminders

- [ ] F-12 Daily reminder notification (`flutter_local_notifications`, Android only)
- [ ] F-13 Private, on-device prayer streak / journal
- [ ] F-14 Liturgical-season mystery suggestion (Advent, Lent Sundays)

## Iteration 4: Distribution

- [ ] O-10 Play Console listing (phone + TV), privacy policy page on Pages
- [ ] O-11 Upload AAB to the Play internal track from `release.yml` (service account)
- [ ] O-12 `integration_test` on an Android emulator in CI (nightly)
- [ ] Q-04 Cross-browser smoke (Chrome, Firefox, Safari) via Playwright on the web build
- [ ] W-02 URL routing (`go_router`) so web refresh/deep links keep the current screen

## Ideas (not committed)

- Divine Mercy Chaplet and other chaplets (the sequence engine is generic enough)
- Human-voice recordings
- Saint of the day
- Optional prayers: St Michael, intentions for the Holy Father, Litany of Loreto
- More languages (PT, IT, DE, TL, PL)

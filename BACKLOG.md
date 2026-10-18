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

- [x] O-07 Default branch `main`, protected: the 3 CI checks are required (ADR-014)
- [x] O-08 Pages enabled (source: GitHub Actions) → https://thejento.github.io/CatholicPrayer/
- [x] O-13 Obsolete `claude/new-session-sjsf1m` branch deleted
- [x] O-15 First Dependabot batch (9 updates) combined into one PR; updates grouped from now on (ADR-019)
- [x] O-09 Upload keystore created and the 4 `ANDROID_*` secrets set (ADR-018); signature verified
- [ ] O-14 **Owner:** back up `~/.config/catholicprayer-signing/` offline
- [x] F-06 Resume an interrupted Rosary (persist session index + mysteries)
- [x] F-07 Animated glow moving between beads (2.3.5 in the original spec)
- [x] Q-02 Golden tests for both themes × phone/tablet/TV sizes (ADR-015)
- [x] Q-03 Raise the coverage gate to 90 %
- [x] T-04 Detect Android TV (platform channel) to apply the 10-foot type scale (ADR-016)
- [ ] C-02 **Owner:** content review of ES/FR texts by a native speaker / parish
- [x] W-01 Proper PWA manifest (name, colours, icons) and favicon (ADR-017)
- [x] T-03 Proper 320×180 TV banner artwork

## Iteration 2: Accessibility & audio

- [x] F-08 Natural voice: pre-rendered Kokoro (EN/ES) + Kyutai (FR, ADR-021), with a freshness check in CI (ADR-020)
- [x] F-09 Auto-advance after the voice finishes, with a 1–5 s pause
- [x] F-16 Voice speed 0.75×–1.25× (pitch preserved), TV play/pause key, credits page
- [ ] C-04 **Owner:** listen to every recording once (44 per language) and flag any mispronunciation — EN and ES approved 2026-10-17; FR to re-check after the Kyutai re-render
- [x] F-10 Semantics audit, automated in CI (ADR-022): labelled beads, announced steps, labelled progress
- [x] F-11 Large text: every screen lays out at 200 % on phone, sideways phone and TV
- [ ] Q-05 Real-device TalkBack pass (reading order, wording) on a phone and a TV emulator

## Iteration 3: Habit & reminders

- [x] F-12 Daily reminder: weekly-per-day local notifications naming the day's mysteries, Android phones only (ADR-023)
- [ ] F-13 Private, on-device prayer streak / journal
- [ ] F-14 Liturgical-season mystery suggestion (Advent, Lent Sundays)

## Iteration 4: Distribution

- [ ] O-10 Play Console listing (phone + TV), privacy policy page on Pages. The icon and feature graphic are ready in `store/`
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

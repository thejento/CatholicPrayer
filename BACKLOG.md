# Backlog

**Open work is tracked in [GitHub Issues](https://github.com/thejento/CatholicPrayer/issues)**
(moved there on 2026-10-18). This file keeps the history of what was done.

Each issue title starts with a stable ID: **F** = feature, **T** = TV, **W** = web,
**Q** = quality, **O** = ops/CI/CD, **C** = content, **I** = idea (not committed).
A new item takes the next free number of its prefix (next: F-33, T-05, W-03, Q-06, O-17, C-05, I-04).
Iterations are milestones; labels give the type, `owner` for the owner's own tasks,
`on hold` when blocked. Close the issue from the PR that does it (`Closes #NN`).
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
- [x] O-16 Security scanning in CI: OSV-Scanner, gitleaks, zizmor, CodeQL, Semgrep Dart rules, Ruff, mobsfscan, MobSF, Scorecard (ADR-032, review r-16, #70)
- [x] O-09 Upload keystore created and the 4 `ANDROID_*` secrets set (ADR-018); signature verified
- [x] F-06 Resume an interrupted Rosary (persist session index + mysteries)
- [x] F-07 Animated glow moving between beads (2.3.5 in the original spec)
- [x] Q-02 Golden tests for both themes × phone/tablet/TV sizes (ADR-015)
- [x] Q-03 Raise the coverage gate to 90 %
- [x] T-04 Detect Android TV (platform channel) to apply the 10-foot type scale (ADR-016)
- [x] W-01 Proper PWA manifest (name, colours, icons) and favicon (ADR-017)
- [x] T-03 Proper 320×180 TV banner artwork

## Iteration 2: Accessibility & audio

- [x] F-08 Natural voice: pre-rendered Kokoro (EN/ES) + Kyutai (FR, ADR-021), with a freshness check in CI (ADR-020)
- [x] F-09 Auto-advance after the voice finishes, with a 1–5 s pause
- [x] F-16 Voice speed 0.75×–1.25× (pitch preserved), TV play/pause key, credits page
- [x] C-04 **Owner:** listen to every recording once (44 per language) and flag any mispronunciation — EN and ES approved 2026-10-17, FR (Kyutai) 2026-10-18
- [x] F-10 Semantics audit, automated in CI (ADR-022): labelled beads, announced steps, labelled progress
- [x] F-11 Large text: every screen lays out at 200 % on phone, sideways phone and TV

## Iteration 3: Habit & reminders

- [x] F-17 Bible passage of each mystery: Douay-Rheims / Torres Amat (modernized) / néo-Crampon (ADR-024)
- [x] F-12 Daily reminder: weekly-per-day local notifications naming the day's mysteries, Android phones only (ADR-023)
- [x] F-14 Liturgical season on Home (named day, colour) and seasonal Sunday mysteries (ADR-025)
- [x] F-19 Saint of the day on Home: General Roman Calendar, ranks, precedence and transfers (ADR-026)
- [x] F-20 More prayers in the library: Memorare, St Michael, Come Holy Spirit, Guardian Angel, Act of Contrition, Angelus, Regina Caeli, Holy Father's intentions (public-domain wordings)
- [x] F-24 About today (season, colour, why these mysteries, the four sets) and saint details with a Vatican News link (ADR-027)
- [x] F-25 A public-domain painting on each mystery announcement, classic theme only (ADR-028)
- [x] F-26 Web footer and Settings → About: version (with commit on deploys), GitHub Issues link, Google Play link (DESIGN §3.14)
- [x] F-28 Auto-advance waits on mystery announcements; each step opens scrolled to the top (owner's first Rosary)
- [x] F-29 Auto-scroll long prayers roughly at the voice's pace (Settings → Voice, on by default)
- [x] F-30 Mysteries-only mode: opening card, five mysteries, closing card; decade ringed on the beads (ADR-029)
- [x] F-31 Classic theme in the colour of the Church year; kid-friendly keeps its own (ADR-030)
- [x] F-32 About this prayer: origin, use and Scripture for every prayer, in the library and the Rosary (ADR-031)

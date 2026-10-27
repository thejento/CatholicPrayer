# Decision Log

Lightweight ADRs (Architecture Decision Records). Each entry is **append-only**.
To reverse a decision, add a new entry that *supersedes* the old one.

Template:

```
## ADR-NNN: Title
- Date: YYYY-MM-DD · Status: Proposed | Accepted | Superseded by ADR-XXX
- Context: why a decision is needed
- Decision: what we chose
- Consequences: trade-offs, follow-ups
```

---

## ADR-001: Flutter as the single cross-platform framework
- Date: 2026-10-14 · Status: Accepted
- Context: The app targets Android phones, Android TV and the web. The existing
  repository scaffold and the original CRC spec already use Flutter.
- Decision: One Flutter codebase for all three targets. Native code only where
  required (Android TV manifest entries).
- Consequences: One language (Dart) and one test stack. The web build uses Flutter's
  renderer, so it is heavier than a hand-written site, which is acceptable for an app-like experience.

## ADR-002: Design-first, documented in the repository
- Date: 2026-10-14 · Status: Accepted
- Context: The app has several platforms, and the owner wants a clear audit trail.
- Decision: `docs/DESIGN.md` is the source of truth for behaviour. `docs/DECISIONS.md`
  records the reasons. `BACKLOG.md` is the ordered work queue. A PR that changes
  behaviour updates the design doc in the same PR.
- Consequences: Slightly more writing per change, but much easier onboarding and review.

## ADR-003: Newcomer guidance as the product's core
- Date: 2026-10-14 · Status: Accepted
- Context: Many rosary apps exist. Most assume the user already knows the structure.
- Decision: Every Rosary step carries a *guidance* sentence (what to do with the
  beads) in addition to the prayer text. Experienced users can turn guidance off.
- Consequences: More text to translate, so each new language costs more.

## ADR-004: Provider + ChangeNotifier for state; pure-Dart domain layer
- Date: 2026-10-14 · Status: Accepted
- Context: Small app and a small team. The spec allowed Provider or BLoC, and `provider` was
  already a dependency.
- Decision: `provider` for dependency injection and state. Rosary logic (sequence, mysteries,
  session) lives in `lib/src/domain` with no Flutter UI imports.
- Consequences: Low ceremony and fast unit tests. If state grows complex,
  revisit (Riverpod/BLoC) through a new ADR.

## ADR-005: Devotional content in JSON assets, UI strings in ARB
- Date: 2026-10-14 · Status: Accepted
- Context: Prayers are long, curated, public-domain texts. UI strings are short and
  change often.
- Decision: Prayers and mysteries go in `assets/data/*.json` with per-language maps. UI
  strings, including step guidance, go in gen-l10n ARB files.
- Consequences: Content can be reviewed by non-developers. Tests enforce key parity
  across languages, so a missing translation fails CI.

## ADR-006: 80-step Dominican Rosary with fixed bead mapping
- Date: 2026-10-14 · Status: Accepted
- Context: Local customs vary (Fatima prayer, intentions, closing prayers).
- Decision: Model the most common form described in DESIGN §4: Sign of the Cross, Creed,
  OF, 3 HM, GB, then 5 × (announce, OF, 10 HM, GB, Fatima), then Hail Holy Queen,
  closing prayer and Sign of the Cross. The bead map is fixed (61 positions).
- Consequences: Simple and testable. Optional prayers (St Michael, intentions for the
  Pope) are in the backlog as settings.

## ADR-007: Mysteries by weekday per *Rosarium Virginis Mariae* (2002)
- Date: 2026-10-14 · Status: Accepted
- Decision: Mon/Sat Joyful, Tue/Fri Sorrowful, Wed/Sun Glorious, Thu Luminous. The user
  can override. The clock is injected so tests are deterministic.

## ADR-008: Android TV in the same APK/AAB
- Date: 2026-10-14 · Status: Accepted
- Context: Separate TV apps double the release effort.
- Decision: One application ID. The manifest declares `LEANBACK_LAUNCHER`,
  `android.software.leanback` and `touchscreen` as *not required*, plus a TV banner.
  D-pad support is built with Flutter `Shortcuts`/`Focus`. These also give keyboard support on the web.
- Consequences: Play Console needs the TV form factor opted in and TV screenshots.

## ADR-009: GitHub Actions for CI/CD; Flutter pinned in pubspec
- Date: 2026-10-14 · Status: Accepted
- Decision: `subosito/flutter-action` reads `environment.flutter` from
  `pubspec.yaml`. Initial pin: **3.47.7** (Dart 3.13). The local SDK used for
  development must match. Workflows: `ci.yml` (PR gate), `deploy-web.yml`
  (GitHub Pages on `main`), `release.yml` (tags → signed AAB/APK on a GitHub
  Release). Dependabot keeps actions and packages current.
- Consequences: Bump the pin deliberately in a PR. CI then proves the upgrade.

## ADR-010: Trunk-based development on `main`
- Date: 2026-10-14 · Status: Accepted
- Context: The repository's only branch was `claude/new-session-sjsf1m`.
- Decision: Create `main` as the default and protected branch. Feature branches merge through
  PRs with CI green.
- Consequences: The GitHub default branch must be switched to `main` (one-time manual step).

## ADR-011: Web hosting on GitHub Pages
- Date: 2026-10-14 · Status: Accepted
- Decision: Deploy `build/web` with the official Pages actions, using `--base-href
  /CatholicPrayer/`. No server is needed because the app is fully static.
- Consequences: A custom domain can be added later (CNAME), which would change the base href to `/`.

## ADR-012: Release signing through GitHub secrets with debug fallback
- Date: 2026-10-14 · Status: Accepted
- Decision: Gradle reads `android/key.properties` when present. CI writes it from
  secrets. Without secrets, the release uses debug signing and the GitHub release is marked
  pre-release, so the pipeline works on day 1.
- Consequences: The upload keystore must be backed up outside GitHub. Losing it blocks
  Play updates unless Play App Signing is enabled (it is recommended).

## ADR-013: Public-domain prayer texts, one content file per language
- Date: 2026-10-14 · Status: Accepted
- Context: Some current liturgical translations are copyrighted, for example ICEL English
  and the AELF 2013 French *Notre Père*. Generating long fixed texts in one block
  also tripped an AI output filter during development.
- Decision: Ship traditional public-domain wordings (English "who art in heaven", French
  *vous* forms, traditional Spanish). Store them as one JSON file per language. If a
  text can't be sourced, a placeholder goes in, and the owner supplies the approved text.
  The owner can later replace any text with a version they hold rights to.
- Consequences: The wording is older in places. A parish or native-speaker review is
  tracked as C-02. Smaller files also make content review diffs easier.

## ADR-014: Public repository
- Date: 2026-10-14 · Status: Accepted
- Context: On the free GitHub plan, a private repository gets neither GitHub Pages
  (ADR-011) nor branch protection (ADR-010).
- Decision: Make `thejento/CatholicPrayer` public. History was scanned first and
  contained no secrets. `main` requires the three CI checks (strict, up to date),
  with no force-push or deletion. Pages publishes from GitHub Actions.
- Consequences: Code, content and commit author emails are public. Secrets must stay
  in GitHub Actions secrets and never be committed (`key.properties` and `*.jks` are
  git-ignored).

## ADR-015: Golden tests with the test font and a small tolerance
- Date: 2026-10-14 · Status: Accepted
- Context: Pixel tests are fragile across machines. Real fonts render differently per OS.
- Decision: Goldens use Flutter's default test font (glyphs drawn as boxes), so they
  check layout and colour, not typography. A comparator accepts up to 0.5 % differing
  pixels. Coverage: Home and the Rosary screen × 2 themes × phone/tablet/TV. CI
  uploads `failures/` diffs as an artifact.
- Consequences: An intentional UI change needs `flutter test --update-goldens test/goldens`
  in the same PR. They already caught the crucifix being clipped on TV.

## ADR-016: Android TV detection through a platform channel
- Date: 2026-10-14 · Status: Accepted
- Context: A TV reports about 960×540 dp, the same as a small tablet, so size alone can't
  trigger the 10-foot UI.
- Decision: `MainActivity` exposes `crc/device#isTelevision` (UI mode television, or the
  Leanback feature). Dart reads it once at startup into `DeviceProfile`, provided
  through `provider`. Any failure, and the web, means "not a TV".
- Consequences: No plugin dependency. Behaviour is unit-tested with a mocked channel.

## ADR-017: Brand assets generated from code
- Date: 2026-10-14 · Status: Accepted
- Decision: Icons, the TV banner and store graphics are rendered by a Dart script
  (`tool/render_icons_test.dart`) instead of being hand-made binaries.
- Consequences: The artwork is reviewable and reproducible. A designer can still
  replace the PNGs later; the script is then retired.

## ADR-018: Release signing key custody
- Date: 2026-10-14 · Status: Accepted
- Decision: A 4096-bit RSA upload key (alias `upload`, PKCS12, valid about 27 years) was
  generated on the owner's workstation in `~/.config/catholicprayer-signing/` (mode
  700/600, outside the repo). It was loaded into the four `ANDROID_*` Actions secrets.
  Certificate SHA-256: `00:C8:6F:F2:81:63:4D:A7:6C:A0:EA:5B:14:0F:8A:CC:43:C2:96:0D:C6:C4:8F:63:5E:B0:AF:50:9F:18:F1:94`.
- Consequences: The owner must back that folder up offline (password manager or
  encrypted drive). Enrol in Play App Signing at first upload, so a lost upload key can
  be reset by Google.

## ADR-019: Grouped Dependabot updates
- Date: 2026-10-14 · Status: Accepted
- Context: The first Dependabot run opened 9 separate PRs. `main` requires PRs to be up
  to date, so each merge forced the others to rebase and re-run CI. One AGP bump
  also failed on its own because it needed the Gradle bump from another PR.
- Decision: Group updates per ecosystem (GitHub Actions, pub, Android/Gradle). Each
  group opens at most one PR per run. Android build tooling always moves in one PR.
- Consequences: At most 3 dependency PRs per cycle. When a group PR fails, the whole
  group waits, so a failing update can be split out manually.

## ADR-020: Natural voice through pre-rendered open-source neural TTS
- Date: 2026-10-14 · Status: Accepted
- Context: The owner wants a smooth, non-robotic, open-source voice. Spoken texts are
  fixed and known in advance. Targets include Android TV and the web, where on-device voices
  vary widely.
- Options considered:
  - **Kokoro-82M** (Apache-2.0 weights; FR voice from SIWIS, CC BY 4.0 → credit
    required). Native EN/ES/FR voices; best graded EN voices `af_heart` (A) and `af_bella` (A−).
    Renders about 5× faster than real time on a laptop CPU, so the whole app renders in minutes.
  - **Chatterbox Multilingual** (MIT, about 0.5B). 23 languages, expressive, with emotion and
    pace controls. It needs PyTorch and around 3 GB of weights, and is much slower on CPU.
  - Qwen3-TTS / VoxCPM2 (Apache-2.0): promising, not sampled yet.
  - Piper: MIT engine, but each voice has its own dataset licence (some are research-only),
    and it sounds less natural. Rejected.
  - Coqui XTTS-v2, Fish Audio, Voxtral: non-commercial licences. Rejected.
  - On-device `flutter_tts`: inconsistent quality, especially on TV and web. Rejected as
    the main voice; it may serve as a fallback for user-added text later.
- Decision: render at build time and ship MP3 clips with a hash manifest, played with
  `just_audio`. After two rounds of blind listening (13 samples, then Bella blends), the owner chose
  **EN: Kokoro Bella**, **ES: Kokoro Dora** and **FR: Chatterbox built-in voice**. Bella was
  preferred overall, but blending her into ES/FR kept an English accent.
  Users can adjust playback speed (0.75×–1.25×) without a re-render.
  *French superseded by ADR-021.*
- Consequences: About 8 MB of audio for 3 languages. Any text edit requires a re-render,
  which CI enforces. Attribution for CC BY voices goes on a credits screen.

## ADR-021: French voice from a native speaker (Kyutai TTS)
- Date: 2026-10-17 · Status: Accepted · Supersedes the French part of ADR-020
- Context: Reviewing all recordings (C-04), the owner found the Chatterbox built-in French
  voice unusable: a strong English accent and frequent audio glitches. English and Spanish were fine.
- Options considered (16 samples, Hail Mary + a guidance line + the Creed, all native
  French speakers, each also transcribed by Whisper to catch dropped words or babble):
  - **Kyutai TTS 1.6B en/fr** (weights CC BY 4.0, code MIT), 8 LibriVox readers from
    CML-TTS (CC BY 4.0). Natural long-form speech; about 12× slower than real time on CPU.
  - **Chatterbox cloning a native reader** (MIT): accent fixed by the reference voice,
    glitch risk unchanged.
  - **Piper** (siwis, tom, upmc): steady, native, but flatter.
  - Kokoro Siwis had already been rejected in ADR-020's test.
- Decision: **Kyutai TTS with reader K2** (`cml-tts/fr/7400_2928_000100-0001_enhanced`,
  female), chosen by ear. Each clip is rendered whole, seeded (seed 42 + attempt) and retried
  when its speaking rate is implausible. Chatterbox is removed from the pipeline.
- Consequences: French renders take about an hour in CI, only when French text changes.
  Credits name Kyutai and the CML-TTS reader (CC BY 4.0). The SIWIS credit is dropped
  because no shipped recording uses it.

## ADR-022: Accessibility checks run in CI on every screen
- Date: 2026-10-17 · Status: Accepted
- Context: Newcomers include older people and people who use screen readers or large
  text. Manual audits drift as screens change.
- Decision: A widget-test suite visits every screen the way a person would, in both themes,
  and applies Flutter's Android tap-target (48 dp), labelled-tap-target and text-contrast
  guidelines. It also lays every screen out at 200 % text on a small phone, a sideways
  phone and a TV (where the 10-foot scale multiplies it to 260 %) and fails on any overflow.
  A screen-reader test checks that steps are announced (live-region heading) and that the
  bead drawing can be activated.
- Findings fixed: the bead drawing exposed an unlabelled tap target next to its labelled
  node (merged into one); step changes were not announced; the progress bar had no label.
- Consequences: Regressions fail CI. Automated checks cannot judge reading order or
  wording, so a real-device TalkBack pass stays a manual item (Q-05).

## ADR-023: Daily reminder with local, inexact weekly notifications
- Date: 2026-10-17 · Status: Accepted
- Context: F-12 asks for a daily nudge. The app has no server and no account, by design.
- Options considered: push notifications (needs a server and Firebase, against the privacy
  model; rejected); exact alarms (needs `SCHEDULE_EXACT_ALARM`, which Android 14 restricts
  and Play reviews; not worth it for a prayer reminder); local inexact notifications.
- Decision: `flutter_local_notifications` (BSD-3) with `timezone` and `flutter_timezone`.
  Seven weekly notifications (weekday + time) so each names that day's mysteries. Android
  phones only. Behind a `ReminderScheduler` interface so logic is unit-tested with a fake.
- Consequences: Two permissions (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`); core-library
  desugaring enabled in Gradle. Delivery can drift by a few minutes.

## ADR-024: Catholic, freely licensed Bible translations for the mystery passages
- Date: 2026-10-17 · Status: Accepted
- Context: The owner asked to show the Bible passage of each mystery. Texts must be public
  domain or openly licensed (ADR-013), and for a Rosary app the Annunciation should read
  "full of grace", as in the Hail Mary.
- Options considered: EN World English Bible Catholic (modern, but "highly favored one"),
  Douay-Rheims; FR Louis Segond 1910 (Protestant), néo-Crampon Libre; ES Reina-Valera 1909
  (Protestant, "muy favorecida"), modern free Spanish Bibles (same wording), Torres Amat
  (Catholic, 1825–1836, no ready-made digital edition).
- Decision: Douay-Rheims (EN), Torres Amat from the Wikisource transcription with the
  spelling modernized (ES, chosen by the owner), néo-Crampon Libre (FR). Passages are
  generated by a script from the sources and committed as JSON.
- Consequences: The French file is CC BY-SA 4.0 (credit on the licence page; excerpts are
  unmodified). The Spanish modernization fixes a few transcription errors and is listed
  word by word, so it can be reviewed; it is part of the native-speaker review (C-02).

## ADR-025: Compute the liturgical calendar on the device
- Date: 2026-10-17 · Status: Accepted
- Context: F-14 asks the suggestion to follow the Church year, and the home screen should
  say where the day falls in it. The app works offline and has no server.
- Options considered: a bundled table of dates (needs yearly updates); an online calendar
  API (network, privacy); computing it from Easter, which fixes every moveable date.
- Decision: a pure-Dart `liturgicalDay(date)` for the General Roman Calendar (seasons,
  numbered Sundays, named days, colours), checked against known dates and over a century.
  Sundays of Advent and Christmas Time suggest the Joyful mysteries, Sundays of Lent the
  Sorrowful ones. Spanish uses Roman numerals for Sundays, as its liturgical books do.
- Consequences: Works for any year with no updates. National calendars (Epiphany and
  Ascension on Sunday in Canada and the United States, national saints) are not covered
  yet (F-21). The saint of the day (F-19) will build on the same engine.

## ADR-026: Saint of the day from a bundled General Roman Calendar
- Date: 2026-10-17 · Status: Accepted
- Context: The owner asked for the saint of the day. The app is offline and private.
- Options considered: an online API (network, availability); the Roman Martyrology (thousands
  of entries, modern translations under copyright); the General Roman Calendar (the saints the
  whole Church celebrates; dates and titles are facts, names written for this app).
- Decision: The General Roman Calendar as a Dart table (date, rank, feast of the Lord) with
  names per language in `assets/data/saints/`, and the precedence and transfer rules that
  matter in practice, on top of the liturgical calendar (ADR-025).
- Consequences: Many weekdays have no saint (the app then shows only the season). Names are
  part of the native-speaker review (C-02). National calendars come later (F-21).

## ADR-027: Link to Vatican News for the saint of the day
- Date: 2026-10-17 · Status: Accepted
- Context: The owner asked for details about the saint of the day and preferred a Church
  source to Wikipedia.
- Options considered: writing biographies (221 saints × 3 languages, risk of errors);
  Wikipedia (not a Church source, per-saint article matching); Vatican News "Saint of the
  day" (the Holy See's news service, one page per date in many languages).
- Decision: Link to the Vatican News page of the date in the app language, opened in the
  browser (`url_launcher`); show the address on TV. Explanations of seasons, colours,
  mysteries and ranks are short texts written for the app, in EN/ES/FR.
- Consequences: Reading about the saint needs a connection and leaves the app; the app
  itself still makes no network calls. If Vatican News changes its addresses, the check
  script shows it.

## ADR-028: Public-domain paintings from CC0 museum collections
- Date: 2026-10-18 · Status: Accepted
- Context: The owner asked for religious artwork during the Rosary, but not in the kid-friendly
  theme, and asked whether it would be a copyright issue.
- Options considered: Wikimedia Commons (works are public domain, but some photos come from
  museums that claim rights, such as Italian state museums for commercial use); museum
  open-access collections released as CC0 (no permission needed); commissioned art (cost).
- Decision: Old-master paintings only from CC0 / public-domain museum releases (National Gallery
  of Art, Cleveland Museum of Art, SMK). One per mystery, chosen by the owner; shown as a card on
  the mystery announcement in the classic theme (owner's choice over a faded background).
- Consequences: About 3 MB more in the app. The Transfiguration and Pentecost are prints because
  no CC0 painting exists in these collections; they can be swapped later if one is found.

## ADR-029: Mysteries-only mode as a second sequence
- Date: 2026-10-25 · Status: Accepted
- Context: The owner asked for an "advanced" mode that only tracks the mysteries, for people
  who know the prayers.
- Options considered: hide the prayer text but keep the 80 steps (still 80 taps); a separate
  screen; a second, shorter sequence driven by the same session, screen, voice and resume code.
  For the start and end: one card each, or nothing. For the decade: a tap counter, or none.
- Decision: A second sequence of 7 steps (`RosaryMode.mysteriesOnly`), chosen on the mystery
  picker and remembered. One summary card each for the opening and closing prayers, and no Hail
  Mary counter (owner's choices). The step model gains `covers` so a mystery highlights its whole
  decade on the beads.
- Consequences: No new texts to record: the summary cards are silent, and the mysteries reuse
  their announcement clips. Everything that walks the steps (voice, resume, progress, beads)
  works for both modes; a tap counter can be added later on the same step model.

## ADR-030: The classic theme follows the liturgical colour of the day
- Date: 2026-10-25 · Status: Accepted
- Context: The owner suggested that the adult (classic) look follow the liturgical period,
  while the kid-friendly look keeps its own attractive colours.
- Options considered: a third theme to choose; the season tinting both themes; the classic
  theme seeded with the day's colour, with a switch to turn it off. For the colour itself: the
  season and its named days (as on Home), or also the saint of the day.
- Decision: The classic theme is seeded with the day's colour from `liturgicalDay()` (on by
  default, switch in Settings). Kid-friendly is unchanged. Saints' days don't change the colour.
  White is drawn as gold, since a white seed gives a grey app.
- Consequences: Material's seeded palettes keep the contrast in every season (checked in the
  accessibility tests). The theme is computed when the app builds, so it changes with the day
  the next time the app is opened. Goldens are taken on a green (Ordinary Time) day.

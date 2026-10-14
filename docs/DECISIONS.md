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

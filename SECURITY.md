# Security policy

Rosary Companion runs offline. It has no account and no server, and it collects no data.
Its settings stay on your device. Security problems can still matter, for example in the
release pipeline, the signing of the Android app, or the web app.

## Reporting a vulnerability

Please report it privately through GitHub:
**[Report a vulnerability](https://github.com/thejento/CatholicPrayer/security/advisories/new)**
(Security tab → "Report a vulnerability"). Please don't open a public issue for a security
problem.

Include what you found, where (app version, Android or web, file or workflow), and the steps
to reproduce it. You should get a reply within a week. Fixes are released as a new version,
and the advisory is published once the fix is out.

## Supported versions

Only the latest release, and the web app at https://thejento.github.io/CatholicPrayer/,
receive fixes.

## How the project checks itself

Every change is scanned for vulnerable dependencies, leaked secrets, unsafe workflows and
unsafe code (see `docs/DESIGN.md` §7.1).

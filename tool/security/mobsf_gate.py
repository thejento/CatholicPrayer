"""Checks a MobSF scorecard against the accepted findings (ADR-032).

  python tool/security/mobsf_gate.py scorecard.json [summary.md]

Prints a Markdown summary (also appended to [summary.md], e.g. the GitHub
job summary) and exits with 1 if a high-severity finding is not listed in
tool/security/mobsf-accepted.txt.
"""
import json
import sys
from pathlib import Path

ACCEPTED = Path(__file__).with_name("mobsf-accepted.txt")


def accepted_titles() -> list[str]:
    lines = ACCEPTED.read_text("utf-8").splitlines()
    return [line.strip() for line in lines if line.strip() and not line.startswith("#")]


def main() -> int:
    card = json.loads(Path(sys.argv[1]).read_text("utf-8"))
    accepted = accepted_titles()
    rows, new = [], []
    for severity in ("high", "warning", "info"):
        for finding in card.get(severity, []):
            title = finding.get("title", "")
            ok = severity != "high" or any(title.startswith(a) for a in accepted)
            if not ok:
                new.append(title)
            status = "accepted" if severity == "high" and ok else ("**new**" if not ok else "")
            rows.append(f"| {severity} | {finding.get('section', '')} | {title} | {status} |")
    summary = "\n".join([
        f"## MobSF scan: {card.get('app_name', '')} {card.get('version_name', '')}",
        "",
        f"Security score **{card.get('security_score')}**/100 · trackers {card.get('trackers')}"
        f" · new high findings **{len(new)}**",
        "",
        "| Severity | Section | Finding | Status |",
        "|---|---|---|---|",
        *rows,
        "",
    ])
    print(summary)
    if len(sys.argv) > 2:
        with open(sys.argv[2], "a", encoding="utf-8") as out:
            out.write(summary + "\n")
    for title in new:
        print(f"::error title=MobSF high finding::{title}")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())

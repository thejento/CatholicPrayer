#!/usr/bin/env bash
# Fails when line coverage in coverage/lcov.info is below the threshold.
# Generated localization code is excluded.
# Usage: scripts/check_coverage.sh [min_percent] [lcov_file]
set -euo pipefail

min="${1:-80}"
file="${2:-coverage/lcov.info}"

awk -v min="$min" '
  /^SF:/ { skip = ($0 ~ /\/generated\//) }
  /^LF:/ && !skip { total += substr($0, 4) }
  /^LH:/ && !skip { hit += substr($0, 4) }
  END {
    if (total == 0) { print "No coverage data found"; exit 1 }
    pct = 100 * hit / total
    printf "Line coverage: %.1f%% (%d/%d lines), minimum %s%%\n", pct, hit, total, min
    if (pct < min) exit 1
  }
' "$file"

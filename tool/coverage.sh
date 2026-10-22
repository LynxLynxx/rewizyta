#!/usr/bin/env bash
# Line coverage per package from the coverage/lcov.info files `flutter test --coverage`
# leaves behind, generated files excluded. Run from the repo root (melos run coverage).
# Only files a test loads appear in lcov.info, so a file no test imports is not counted.
set -euo pipefail
summarise='
  /^SF:/ { skip = ($0 ~ /\.g\.dart$|\.drift\.dart$|\/generated\//) }
  /^LF:/ && !skip { split($0, a, ":"); lf += a[2] }
  /^LH:/ && !skip { split($0, a, ":"); lh += a[2] }
  END { printf "%-32s %6d / %-6d %5.1f%%\n", name, lh, lf, lf ? 100 * lh / lf : 0 }'
files=$(ls apps/*/coverage/lcov.info packages/*/coverage/lcov.info 2>/dev/null || true)
[ -z "$files" ] && { echo "no coverage/lcov.info found; run flutter test --coverage first" >&2; exit 1; }
for f in $files; do
  awk -v name="$(dirname "$(dirname "$f")")" "$summarise" "$f"
done
# shellcheck disable=SC2086
cat $files | awk -v name="total" "$summarise"

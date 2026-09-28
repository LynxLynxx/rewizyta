#!/usr/bin/env bash
# dart format for the current package, skipping generated files.
# Usage: format.sh [--check]
set -euo pipefail
args=()
[ "${1:-}" = "--check" ] && args=(--output=none --set-exit-if-changed)
files=$(find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.drift.dart' ! -path '*/generated/*' 2>/dev/null || true)
[ -z "$files" ] && exit 0
# shellcheck disable=SC2086
dart format ${args[@]+"${args[@]}"} $files

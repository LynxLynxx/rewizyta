#!/usr/bin/env bash
# Fails when a package imports across a layer boundary. pubspec dependencies
# already stop most of it; these greps catch the transitive cases Dart allows.
set -euo pipefail
cd "$(dirname "$0")/.."
status=0

check() {
  local label="$1"; shift
  if hits=$(grep -rn --include='*.dart' "$@" 2>/dev/null) && [ -n "$hits" ]; then
    echo "LAYERING: $label"; echo "$hits"; status=1
  fi
}

# 1. Flutter below the presentation layer (foundation is tolerated).
check "Flutter in models/repositories/services" \
  -E "package:flutter/(material|widgets|cupertino)" \
  packages/rewizyta_models/lib packages/rewizyta_repositories/lib packages/rewizyta_services/lib
# 2. Cubits reaching into the data layer.
check "blocs import repositories" -E "package:rewizyta_repositories/" packages/rewizyta_blocs/lib
# 3. View models reaching into state or data.
check "view_models import blocs/services/repositories" \
  -E "package:rewizyta_(blocs|services|repositories)/" packages/rewizyta_view_models/lib
# 4. Pages bypassing services: only the DI container may import repositories.
check "app imports repositories outside dependencies.dart" \
  -E "package:rewizyta_repositories/" apps/mobile/lib --exclude=dependencies.dart
# 5. Cross-package private imports.
if hits=$(grep -rn --include='*.dart' -E "package:rewizyta_[a-z_]+/src/" apps packages 2>/dev/null \
    | awk -F: '{ split($1, p, "/"); pkg = (p[1]=="packages") ? p[2] : "rewizyta"; if ($0 !~ "package:" pkg "/src/") print }') \
   && [ -n "$hits" ]; then
  echo "LAYERING: cross-package src/ import"; echo "$hits"; status=1
fi

[ $status -eq 0 ] && echo "layering: ok"
exit $status

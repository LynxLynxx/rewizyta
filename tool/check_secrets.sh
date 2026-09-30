#!/usr/bin/env bash
# Scans the working tree (and, with --history, every commit) for secrets and
# personal data that must not reach a public repository.
#
#   tool/check_secrets.sh            # working tree, incl. untracked files
#   tool/check_secrets.sh --staged   # what `git commit` is about to record (pre-commit hook)
#   tool/check_secrets.sh --history  # full git history (CI)
#
# Two layers: gitleaks (rules in .gitleaks.toml) for credentials, then a few
# greps for things gitleaks does not know are sensitive here: real Polish phone
# numbers, e-mail addresses and hosted project hostnames outside the fixtures.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:---tree}"
status=0

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "secrets: gitleaks is not installed (brew install gitleaks); running the grep layer only" >&2
else
  case "$mode" in
    --staged)  gitleaks git --staged --no-banner --redact --config .gitleaks.toml . || status=1 ;;
    --history) gitleaks git --no-banner --redact --config .gitleaks.toml . || status=1 ;;
    *)         gitleaks dir --no-banner --redact --config .gitleaks.toml . || status=1 ;;
  esac
fi

# Files to grep: staged content for --staged, otherwise every tracked + untracked file.
if [ "$mode" = "--staged" ]; then
  files=$(git diff --cached --name-only --diff-filter=ACMR)
else
  files=$(git ls-files --cached --others --exclude-standard)
fi
files=$(printf '%s\n' "$files" | grep -vE '(^|/)(pubspec\.lock|\.gitleaks\.toml)$|\.(png|jpg|jpeg|webp|ico|ttf|woff2?|svg)$' || true)
[ -z "$files" ] && { [ $status -eq 0 ] && echo "secrets: ok"; exit $status; }

check() {
  local label="$1" pattern="$2" exclude="${3:-^$}"
  if hits=$(printf '%s\n' "$files" | xargs grep -nIE "$pattern" 2>/dev/null | grep -vE "$exclude" || true) && [ -n "$hits" ]; then
    echo "SECRETS: $label"; echo "$hits"; status=1
  fi
}

# Polish mobile numbers other than the shared fixture +48 601 234 567.
check "phone number that is not the test fixture" \
  '(^|[^0-9A-Za-z])(\+48 ?)?[5-8][0-9]{2}[ -]?[0-9]{3}[ -]?[0-9]{3}([^0-9A-Za-z]|$)' \
  '601[ -]?234[ -]?567|\.pbxproj:|\.svg:|[0-9]{3} [0-9]{3} [0-9]{3} [0-9]|version|rgb|#[0-9a-fA-F]{6}'
# E-mail addresses outside the documented example domains, except the public
# contact address the website names as the data controller's.
check "e-mail address" \
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' \
  '@(example\.(com|org|pl)|rewizyta\.pl)\b|r\.schossler@rsapps\.org|noreply@anthropic\.com|Co-Authored-By|@[0-9.]+x\.(png|jpg|jpeg|webp)'
# Hosted project hostnames: the app must read these from .env.
check "hosted backend hostname" \
  '[a-z0-9-]+\.(supabase\.co|ingest\.(de|us)\.sentry\.io|posthog\.com/project)' \
  'eu\.i\.posthog\.com|<ref>\.supabase\.co|<project-ref>'
# Files that must never be committed.
private_files=$(printf '%s\n' "$files" | grep -E '^docs/private/' || true)
if [ -n "$private_files" ]; then echo "SECRETS: docs/private/ is git-ignored on purpose; never stage it"; echo "$private_files"; status=1; fi
status_files=$(printf '%s\n' "$files" | grep -E '(^|/)(\.env(\..*)?|google-services\.json|GoogleService-Info\.plist|.*\.jks|.*\.keystore|key\.properties|.*\.p12|.*\.pem)$' | grep -vE '\.env\.example$' || true)
if [ -n "$status_files" ]; then echo "SECRETS: local config file in the tree"; echo "$status_files"; status=1; fi

[ $status -eq 0 ] && echo "secrets: ok"
exit $status

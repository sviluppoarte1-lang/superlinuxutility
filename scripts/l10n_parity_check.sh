#!/usr/bin/env bash
# l10n parity check for CI / pre-commit.
#
# Verifies that every localized .arb file (lib/l10n/app_<lang>.arb) declares
# the exact same set of real keys and does not contain empty translation values.
# Excludes @@-prefixed JSON-LD metadata (locale, placeholders, descriptions).
#
# Exit code: 0 = OK (all files share identical key sets + no empty values),
#           1 = mismatch found (CI fails / commit blocked).
#
# Usage: scripts/l10n_parity_check.sh [arb_dir]   # default: lib/l10n
set -euo pipefail

ARB_DIR="${1:-lib/l10n}"
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required (apt install jq / dnf install jq)" >&2
  exit 2
fi

shopt -s nullglob
files=( "$ARB_DIR"/app_*.arb )
shopt -u nullglob
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no app_*.arb files found in $ARB_DIR" >&2
  exit 2
fi

ref_file="$ARB_DIR/app_en.arb"
ref_keys="$(jq -r 'keys_unsorted[] | select(startswith("@")|not)' "$ref_file" | sort)"
ref_count="$(printf '%s' "$ref_keys" | grep -c . || true)"
echo "Reference (app_en): ${ref_count} keys"

overall=0
for f in "${files[@]}"; do
  lang="$(basename "$f" .arb | sed 's/^app_//')"
  [[ "$lang" == "en" ]] && continue

  keys="$(jq -r 'keys_unsorted[] | select(startswith("@")|not)' "$f" | sort)"
  count="$(printf '%s' "$keys" | grep -c . || true)"

  # Missing keys: present in en, absent here.
  missing=$(comm -23 <(printf '%s' "$ref_keys") <(printf '%s' "$keys"))
  # Extra keys: present here, absent from en.
  extra=$(comm -13 <(printf '%s' "$ref_keys") <(printf '%s' "$keys"))

  status="ok"
  if [ "$count" -ne "$ref_count" ] || [ -n "${missing// /}" ] || [ -n "${extra// /}" ]; then
    status="MISMATCH"
    overall=1
  fi
  printf '[%-2s] %5d keys ' "$lang" "$count"
  if [ "$status" = "ok" ]; then
    echo "(parity ok)"
  else
    echo "(parity MISMATCH)"; 
    [ -n "${missing// /}" ] && echo "        missing from $lang: $(printf '%s\n' "$missing" | tr '\n' ' ')"
    [ -n "${extra// /}" ]   && echo "        extra in $lang:    $(printf '%s\n' "$extra"  | tr '\n' ' ')"
  fi
done

# Empty-value check across every file (translation not filled yet).
echo "--- empty-value scan ---"
for f in "${files[@]}"; do
  # Only strings are translatable; skip @@ metadata. Uses var-binding to avoid jq pipe/and precedence issues.
  empties="$(jq -r 'to_entries[] | .key as $k | .value as $v | select(($v|type)=="string" and ($k|startswith("@")|not) and ($v=="")) | $k' "$f" | sort | tr '\n' ' ')"
  if [ -n "${empties// /}" ]; then
    lang="$(basename "$f" .arb | sed 's/^app_//')"
    echo "[${lang}] EMPTY VALUES: $empties"
    overall=1
  fi
done

if [ "$overall" -eq 0 ]; then
  echo "PASS: all ${#files[@]} locales share identical key sets and no empty translations."
fi
exit "$overall"

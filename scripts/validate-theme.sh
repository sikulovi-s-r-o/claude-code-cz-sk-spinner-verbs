#!/usr/bin/env bash
# Validate spinery theme JSON files against schema + custom rules.
# Usage: ./scripts/validate-theme.sh themes/**/*.json
# Or:    ./scripts/validate-theme.sh themes/cs/cimrman.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
SCHEMA="${PLUGIN_ROOT}/schemas/theme.schema.json"
THEMES_DIR="${PLUGIN_ROOT}/themes"

LOCALE_DIRS=("cs" "sk" "en" "community")

red()   { printf '\033[31m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow(){ printf '\033[33m%s\033[0m' "$*"; }

die() { printf '%s %s\n' "$(red 'FAIL:')" "$1" >&2; exit 1; }
warn(){ printf '%s %s\n' "$(yellow 'WARN:')" "$1" >&2; }
pass(){ printf '%s %s\n' "$(green 'OK:')"   "$1"; }

require_ajv() {
  if ! command -v ajv >/dev/null 2>&1; then
    die "ajv-cli is required. Install: npm install -g ajv-cli ajv-formats"
  fi
}

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required. Install via: brew install jq"
}

validate_schema() {
  local file="$1"
  if ! ajv validate -s "$SCHEMA" -d "$file" >/dev/null 2>&1; then
    # Re-run with output visible for debugging
    ajv validate -s "$SCHEMA" -d "$file" || true
    die "Schema validation failed: $file"
  fi
}

validate_filename_matches_name() {
  local file="$1"
  local expected actual
  expected=$(basename "$file" .json)
  actual=$(jq -r '.name' "$file")
  if [[ "$expected" != "$actual" ]]; then
    die "Filename '${expected}.json' does not match .name field '${actual}' in $file"
  fi
}

validate_locale_tag() {
  local file="$1"
  local locale has_tag
  locale=$(basename "$(dirname "$file")")
  # Skip if file is directly under themes/ (unlikely)
  [[ "$locale" == "themes" ]] && return 0
  # community/ does not require a locale tag
  if [[ "$locale" == "community" ]]; then
    local tag_count
    tag_count=$(jq -r '.tags | length' "$file")
    if [[ "$tag_count" -lt 2 ]]; then
      die "themes/community/ packs must have at least 2 tags: $file"
    fi
    return 0
  fi
  # Locale folders (cs, sk, en, ...) require matching tag
  if [[ " ${LOCALE_DIRS[*]} " == *" $locale "* ]]; then
    has_tag=$(jq -r --arg l "$locale" '.tags | index($l) != null' "$file")
    if [[ "$has_tag" != "true" ]]; then
      die "Pack in themes/${locale}/ must include '${locale}' in tags: $file"
    fi
  fi
}

validate_global_uniqueness() {
  # Scan all themes, flag duplicate names
  local seen=()
  local f name
  while IFS= read -r f; do
    name=$(jq -r '.name' "$f")
    for s in "${seen[@]:-}"; do
      if [[ "$s" == "$name" ]]; then
        die "Duplicate theme name '${name}' found across themes/ (breaks /spinner <name> resolution)"
      fi
    done
    seen+=("$name")
  done < <(find "$THEMES_DIR" -type f -name '*.json' ! -name '_template.json' | sort)
}

main() {
  require_jq
  require_ajv

  if [[ $# -eq 0 ]]; then
    # Default: validate everything
    mapfile -t files < <(find "$THEMES_DIR" -type f -name '*.json' ! -name '_template.json' 2>/dev/null) || true
    if [[ ${#files[@]:-0} -eq 0 ]]; then
      # bash 3 fallback
      files=()
      while IFS= read -r f; do files+=("$f"); done < <(find "$THEMES_DIR" -type f -name '*.json' ! -name '_template.json')
    fi
  else
    files=("$@")
  fi

  local ok=0 total=0
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || { warn "skipping missing: $f"; continue; }
    total=$((total + 1))
    validate_schema "$f"
    validate_filename_matches_name "$f"
    validate_locale_tag "$f"
    pass "$(basename "$(dirname "$f")")/$(basename "$f")"
    ok=$((ok + 1))
  done

  validate_global_uniqueness

  printf '\n%s %d/%d themes valid, names globally unique.\n' "$(green '✓')" "$ok" "$total"
}

main "$@"

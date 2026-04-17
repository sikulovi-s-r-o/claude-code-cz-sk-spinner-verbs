#!/usr/bin/env bash
# spinery — Claude Code spinner pack manager
# https://github.com/sikulam/spinery
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
THEMES_DIR="${PLUGIN_ROOT}/themes"

# Claude Code config directory:
#   - native install sets CLAUDE_CONFIG_DIR in the shell (usually ~/.claude-work)
#   - npm install defaults to ~/.claude
# Honor the env var when present so spinery writes where Claude Code reads.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
SETTINGS="${CLAUDE_DIR}/settings.json"
STATE_FILE="${CLAUDE_DIR}/spinery.state"

# ---------- util ----------

die() { printf 'spinery: %s\n' "$1" >&2; exit "${2:-1}"; }

require_jq() {
  command -v jq >/dev/null 2>&1 || die "jq is required. Install via: brew install jq  (macOS)  or  sudo apt install jq  (Debian/Ubuntu)" 2
}

ensure_settings_file() {
  local dir
  dir="$(dirname "$SETTINGS")"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  if [[ ! -f "$SETTINGS" ]]; then
    printf '{}\n' > "$SETTINGS"
  fi
  if ! jq empty "$SETTINGS" 2>/dev/null; then
    die "$SETTINGS is not valid JSON. Fix it manually or back it up and let spinery recreate it." 3
  fi
}

list_theme_files() {
  find "$THEMES_DIR" -type f -name '*.json' ! -name '_template.json' | sort
}

find_theme() {
  # Usage: find_theme <name-or-path>; echoes absolute path on success.
  local name="$1"
  if [[ "$name" == */* ]]; then
    local candidate="${THEMES_DIR}/${name}.json"
    [[ -f "$candidate" ]] || die "Theme not found: ${name} (expected ${candidate})"
    printf '%s\n' "$candidate"
    return 0
  fi

  local matches=()
  local f
  while IFS= read -r f; do
    matches+=("$f")
  done < <(find "$THEMES_DIR" -type f -name "${name}.json" ! -name '_template.json')

  case "${#matches[@]}" in
    0)
      local suggestion
      suggestion=$(list_theme_files | sed -E "s|.*/([^/]+)\.json|\1|" | awk -v q="$name" 'BEGIN{best=""; bd=99} {d=length($0); if (index($0,q)||index(q,$0)) {if (d<bd){best=$0; bd=d}}} END{print best}')
      if [[ -n "$suggestion" ]]; then
        die "Unknown theme: ${name}. Did you mean '${suggestion}'? Use /spinner list to see all."
      else
        die "Unknown theme: ${name}. Use /spinner list to see all."
      fi
      ;;
    1)
      printf '%s\n' "${matches[0]}"
      ;;
    *)
      {
        printf 'Multiple themes match "%s":\n' "$name"
        printf '  - %s\n' "${matches[@]}"
        printf 'Disambiguate with locale prefix, e.g. cs/%s\n' "$name"
      } >&2
      exit 3
      ;;
  esac
}

atomic_write_settings() {
  # Stdin = new JSON, write atomically to $SETTINGS.
  local tmp="${SETTINGS}.tmp.$$"
  cat > "$tmp"
  mv -f "$tmp" "$SETTINGS"
}

write_state() { printf '%s\n' "$1" > "$STATE_FILE"; }
read_state()  { [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || printf ''; }
clear_state() { rm -f "$STATE_FILE"; }

# ---------- subcommands ----------

cmd_help() {
  cat <<'EOF'
spinery — Claude Code spinner pack manager

Usage:
  /spinner <name>               Apply a theme by name (e.g. cimrman, cs/cimrman)
  /spinner list                 List available themes
  /spinner status               Show currently applied theme
  /spinner random               Pick a random theme and apply it
  /spinner off                  Remove spinnerVerbs, restore defaults
  /spinner install-autorotate   Install shell wrapper that rotates on each `claude` start
  /spinner uninstall-autorotate Remove the shell wrapper

Learn more: https://github.com/sikulam/spinery
EOF
}

cmd_list() {
  local file name description tags locale count
  local total=0
  printf 'Available themes:\n\n'
  printf '  %-16s  %-8s  %-6s  %s\n' 'NAME' 'LOCALE' 'VERBS' 'DESCRIPTION'
  printf '  %-16s  %-8s  %-6s  %s\n' '----' '------' '-----' '-----------'
  while IFS= read -r file; do
    name=$(jq -r '.name' "$file")
    description=$(jq -r '.description' "$file")
    count=$(jq -r '.spinnerVerbs.verbs | length' "$file")
    locale=$(basename "$(dirname "$file")")
    printf '  %-16s  %-8s  %-6s  %s\n' "$name" "$locale" "$count" "$description"
    total=$((total + 1))
  done < <(list_theme_files)
  printf '\n%d themes. Apply with: /spinner <name>\n' "$total"
}

cmd_status() {
  ensure_settings_file
  local current has_verbs
  has_verbs=$(jq -r 'has("spinnerVerbs")' "$SETTINGS")
  current=$(read_state)
  if [[ "$has_verbs" == "true" ]]; then
    local mode count
    mode=$(jq -r '.spinnerVerbs.mode // "replace"' "$SETTINGS")
    count=$(jq -r '.spinnerVerbs.verbs | length' "$SETTINGS")
    if [[ -n "$current" ]]; then
      printf 'Current theme: %s (mode=%s, %d verbs)\n' "$current" "$mode" "$count"
    else
      printf 'spinnerVerbs is set (mode=%s, %d verbs), but not applied by spinery (manual edit?).\n' "$mode" "$count"
    fi
  else
    printf 'No custom spinner theme active. Claude Code defaults are in effect.\n'
  fi
}

cmd_off() {
  ensure_settings_file
  local has_verbs
  has_verbs=$(jq -r 'has("spinnerVerbs")' "$SETTINGS")
  if [[ "$has_verbs" != "true" ]]; then
    printf 'No spinnerVerbs set. Nothing to do.\n'
    clear_state
    return 0
  fi
  jq 'del(.spinnerVerbs)' "$SETTINGS" | atomic_write_settings
  clear_state
  printf '✓ Cleared spinnerVerbs. Default Claude Code verbs restored.\n'
}

cmd_apply() {
  local name="$1"
  ensure_settings_file
  local theme_file
  theme_file=$(find_theme "$name")
  local mode verbs display_name count
  mode=$(jq -r '.spinnerVerbs.mode // "replace"' "$theme_file")
  verbs=$(jq '.spinnerVerbs.verbs' "$theme_file")
  display_name=$(jq -r '.name' "$theme_file")
  count=$(jq -r '.spinnerVerbs.verbs | length' "$theme_file")
  jq --arg mode "$mode" --argjson verbs "$verbs" \
     '.spinnerVerbs = {mode: $mode, verbs: $verbs}' \
     "$SETTINGS" | atomic_write_settings
  write_state "$display_name"
  printf '✓ Applied %s theme (%d verbs, mode=%s). New verbs active on next prompt.\n' \
    "$display_name" "$count" "$mode"
}

cmd_random() {
  local themes=()
  local f
  while IFS= read -r f; do
    themes+=("$f")
  done < <(list_theme_files)
  if [[ ${#themes[@]} -eq 0 ]]; then
    die "No themes found in $THEMES_DIR"
  fi
  local pick
  pick="${themes[RANDOM % ${#themes[@]}]}"
  local name
  name=$(jq -r '.name' "$pick")
  printf '🎲 '
  cmd_apply "$name"
}

# -------- autorotate (shell wrapper) --------

detect_rc_file() {
  local shell_base
  shell_base=$(basename "${SHELL:-}")
  case "$shell_base" in
    zsh)  printf '%s\n' "${HOME}/.zshrc" ;;
    bash)
      if [[ -f "${HOME}/.bashrc" ]]; then
        printf '%s\n' "${HOME}/.bashrc"
      else
        printf '%s\n' "${HOME}/.bash_profile"
      fi
      ;;
    fish)
      die "fish shell is not yet supported by install-autorotate. Please open an issue or PR: https://github.com/sikulam/spinery"
      ;;
    *)
      die "Unknown shell '${shell_base}'. Set SHELL or install manually per README."
      ;;
  esac
}

AUTOROTATE_BEGIN='# === spinery-autorotate:begin ==='
AUTOROTATE_END='# === spinery-autorotate:end ==='

autorotate_block() {
  cat <<EOF
${AUTOROTATE_BEGIN}
# Managed by spinery; remove with: /spinner uninstall-autorotate
__spinery_rotate() { "${SCRIPT_DIR}/spinner.sh" random >/dev/null 2>&1 || true; }
claude() { __spinery_rotate; command claude "\$@"; }
${AUTOROTATE_END}
EOF
}

cmd_install_autorotate() {
  local rc
  rc=$(detect_rc_file)
  [[ -f "$rc" ]] || touch "$rc"
  if grep -qF "$AUTOROTATE_BEGIN" "$rc" 2>/dev/null; then
    printf 'Autorotate already installed in %s.\n' "$rc"
    printf 'To reinstall, first run: /spinner uninstall-autorotate\n'
    return 0
  fi
  {
    printf '\n'
    autorotate_block
  } >> "$rc"
  printf '✓ Installed autorotate wrapper in %s\n' "$rc"
  printf '  Each time you run `claude`, a random theme will be applied first.\n'
  printf '  Reload shell: source %s  (or open a new terminal)\n' "$rc"
  printf '  Remove with: /spinner uninstall-autorotate\n'
}

cmd_uninstall_autorotate() {
  local rc
  rc=$(detect_rc_file)
  if [[ ! -f "$rc" ]] || ! grep -qF "$AUTOROTATE_BEGIN" "$rc"; then
    printf 'No autorotate block found in %s. Nothing to do.\n' "$rc"
    return 0
  fi
  local tmp="${rc}.tmp.$$"
  awk -v begin="$AUTOROTATE_BEGIN" -v end="$AUTOROTATE_END" '
    index($0, begin) { skip=1; next }
    index($0, end)   { skip=0; next }
    !skip            { print }
  ' "$rc" > "$tmp"
  # Squash any resulting trailing blank lines
  awk 'BEGIN{blank=0} /^$/{blank++; next} {for(i=0;i<blank;i++)print ""; blank=0; print}' "$tmp" > "${tmp}.2"
  mv -f "${tmp}.2" "$rc"
  rm -f "$tmp"
  printf '✓ Removed autorotate wrapper from %s\n' "$rc"
  printf '  Reload shell: source %s  (or open a new terminal)\n' "$rc"
}

# ---------- main ----------

require_jq

case "${1:-}" in
  ""|-h|--help|help)       cmd_help ;;
  list)                    cmd_list ;;
  status)                  cmd_status ;;
  off)                     cmd_off ;;
  random)                  cmd_random ;;
  install-autorotate)      cmd_install_autorotate ;;
  uninstall-autorotate)    cmd_uninstall_autorotate ;;
  *)                       cmd_apply "$1" ;;
esac

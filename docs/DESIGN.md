# Spinery — Spinner Packs for Claude Code

**Status:** Draft (brainstorm output, pending implementation plan)
**Date:** 2026-04-17
**Repo target:** `github.com/sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs`
**License:** MIT

## Problem & motivation

Claude Code 2.1.23+ supports customizing spinner verbs (`~/.claude/settings.json` → `spinnerVerbs`). An English-language community has formed around themed verb packs (AlexPl292's `awesome-claude-spinners`, Suntory-N-Water's `cc-spinner`, wynandw87's massive README collection). There is **no curated Czech/Slovak content** and no plugin that offers first-class CZ/SK packs alongside English ones.

**Goals:**
1. Publish a polished Claude Code plugin with curated spinner packs
2. Make Czech & Slovak packs the flagship content; welcome community packs in any language
3. Ship features the competition lacks: `random`, `install-autorotate`, `off`, `status`
4. Lower the bar for community contributions (schema-validated PRs, template, CI)

**Non-goals:**
- npm/CLI distribution (cc-spinner covers that)
- Binary patching for unsupported features (tweakcc covers that)
- Localized documentation (target audience is developers, English is standard on GitHub)

## Positioning

> *"Claude Code spinner packs — curated themes, feature-rich, with first-class Czech & Slovak content."*

Differentiators against existing solutions:

| | wynandw87 | AlexPl292 | cc-spinner | **spinery** |
|---|---|---|---|---|
| Distribution | copy-paste README | JSON repo + slash cmd | npm CLI | **plugin + JSON repo** |
| Dynamic slash cmd | ✗ | ✗ (one dispatcher) | ✗ | **✓ (`/spinner <theme>`)** |
| `random` | ✗ | ✗ | ✗ | **✓** |
| `install-autorotate` | ✗ | ✗ | ✗ | **✓ (V1)** |
| `status` / `off` | ✗ | partial (off only) | ✗ | **✓** |
| CZ/SK first-class content | ✗ | ✗ | ✗ | **✓ (flagship)** |

## Architecture

Claude Code plugins are static collections of markdown commands + supporting files. The LLM invokes commands; commands may shell out via Bash. **Design choice: all logic in deterministic shell scripts**, the slash command is a thin bridge. Reasons: testability outside Claude Code, zero LLM variability on file edits, atomic writes.

**Flow for `/spinner <theme>`:**

```
User: /spinner cimrman
  ↓
Claude Code loads commands/spinner.md into context
  ↓
Command instructs Claude to invoke Bash: scripts/spinner.sh cimrman
  ↓
spinner.sh:
  1. validates themes/**/cimrman.json exists (globally unique name)
  2. loads verbs JSON via jq
  3. merges into ~/.claude/settings.json under spinnerVerbs key
     (atomic write via .tmp + rename; preserves all other settings)
  4. prints: ✓ Applied cimrman theme (32 verbs). New verbs active on next prompt.
  ↓
Claude relays script output verbatim to user
```

All subcommands (`random`, `list`, `status`, `off`, `install-autorotate`, `uninstall-autorotate`) route through the same dispatcher.

**Hot-reload:** Verified during live testing — Claude Code re-reads `spinnerVerbs` via `k8().spinnerVerbs` at each spinner mount (`useState` initializer), so a new theme takes effect on the next prompt in the same session. No restart required.

## Repository structure

```
spinery/
├── .claude-plugin/
│   └── plugin.json                      # manifest (name, version, commands)
├── commands/
│   └── spinner.md                       # single dispatcher command
├── scripts/
│   ├── spinner.sh                       # main dispatcher (all subcommands)
│   └── validate-theme.sh                # JSON schema + custom rule checker
├── themes/
│   ├── _template.json                   # starter for new contributions
│   ├── cs/
│   │   ├── cimrman.json
│   │   └── pelisky.json
│   ├── sk/                              # empty, ready for PRs
│   ├── en/                              # empty, ready for PRs
│   └── community/                       # language-agnostic packs
├── schemas/
│   └── theme.schema.json                # JSON Schema (draft-07)
├── README.md                            # EN, "Featured: CZ/SK packs" prominent
├── CONTRIBUTING.md                      # EN, PR template + validation steps
├── LICENSE                              # MIT
└── .github/
    ├── workflows/ci.yml                 # validate themes on PR
    └── PULL_REQUEST_TEMPLATE.md         # contributor checklist
```

## `.claude-plugin/plugin.json`

```json
{
  "name": "spinery",
  "displayName": "Spinery — Spinner Packs for Claude Code",
  "description": "Curated spinner verb packs with first-class Czech & Slovak content",
  "version": "0.1.0",
  "author": {
    "name": "sikulam",
    "url": "https://github.com/sikulam"
  },
  "homepage": "https://github.com/sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs",
  "license": "MIT",
  "commands": ["./commands/spinner.md"]
}
```

**Note:** Exact manifest schema (field names, whether `commands` takes paths or is auto-discovered from `commands/` folder) should be verified against current Claude Code plugin documentation during implementation. The example above reflects conventions observed in existing community plugins.

## `commands/spinner.md`

```markdown
---
description: Apply, list, randomize, or remove spinner verb packs
argument-hint: <theme-name> | list | random | off | status | install-autorotate
---

Run the spinner dispatcher with the user's arguments:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/spinner.sh" $ARGUMENTS`

Relay the script's output to the user verbatim. If the script exits with non-zero, show the error message.
```

**Notes:**
- `$ARGUMENTS` — Claude Code-provided placeholder for slash command args
- `${CLAUDE_PLUGIN_ROOT}` — absolute path to installed plugin root, set by Claude Code
- `!` prefix — Claude Code executes the Bash tool directly; no LLM reasoning over output
- "Relay verbatim" — instructs LLM not to paraphrase script output (preserves formatting)

## `scripts/spinner.sh` — dispatcher

**Dependencies:** `bash` (portable pattern, works on macOS default 3.2 and Linux 4+), `jq`.

**Top-level shape:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"
THEMES_DIR="$(dirname "$0")/../themes"

require_jq || die "jq required — install via brew/apt"
ensure_settings_file    # create {} if missing

case "${1:-}" in
  ""|-h|--help)          cmd_help ;;
  list)                  cmd_list ;;
  status)                cmd_status ;;
  off)                   cmd_off ;;
  random)                cmd_random ;;
  install-autorotate)    cmd_install_autorotate ;;
  uninstall-autorotate)  cmd_uninstall_autorotate ;;
  *)                     cmd_apply "$1" ;;
esac
```

**Theme resolution:** `cimrman` → recursive glob `themes/**/cimrman.json`. Multiple matches → fatal (prevented by CI uniqueness check). Users can disambiguate with `cs/cimrman`.

**Atomic write pattern:**

```bash
apply_verbs() {
  local theme_file="$1" verbs mode tmp
  mode=$(jq -r '.spinnerVerbs.mode // "replace"' "$theme_file")
  verbs=$(jq '.spinnerVerbs.verbs' "$theme_file")
  tmp="${SETTINGS}.tmp.$$"
  jq --arg mode "$mode" --argjson verbs "$verbs" \
     '.spinnerVerbs = {mode: $mode, verbs: $verbs}' \
     "$SETTINGS" > "$tmp"
  mv -f "$tmp" "$SETTINGS"   # atomic rename
}
```

**Random selection (no `shuf` dependency, bash 3.2 compatible):**

```bash
themes=()
while IFS= read -r line; do themes+=("$line"); done < <(find "$THEMES_DIR" -name '*.json' ! -name '_template.json')
pick="${themes[RANDOM % ${#themes[@]}]}"
```

**`install-autorotate` writes to shell rc with idempotence marker:**

```bash
# === spinery autorotate (do not edit) ===
claude() { "${CLAUDE_PLUGIN_ROOT:-}/scripts/spinner.sh" random >/dev/null; command claude "$@"; }
# === /spinery autorotate ===
```

Detects `$SHELL` to target `~/.zshrc` or `~/.bashrc`. Fish shell: warn and exit with instructions. `uninstall-autorotate` uses `sed` to strip the marker block.

**Edge cases:**

| Case | Behavior |
|---|---|
| `~/.claude/settings.json` missing | Create `{}` via `mkdir -p` + `echo '{}'` |
| `settings.json` is invalid JSON | Refuse; offer `--force` flag (with confirmation) |
| Theme name not found | "Unknown theme 'cimrmann'. Did you mean 'cimrman'?" + list hint |
| `jq` missing | Print install hint (brew/apt), exit 2 |
| Duplicate theme name across folders | Fatal; reference the offending files |
| Fish shell at `install-autorotate` | Warn, exit 1, link to manual alternative in README |

**Exit codes:**
- `0` — success
- `1` — user error (bad theme, bad arg)
- `2` — system error (missing `jq`, permission denied)
- `3` — corrupted state (malformed settings.json, duplicate themes)

## Theme JSON schema

`schemas/theme.schema.json` (draft-07):

```json
{
  "$schema": "https://json-schema.org/draft-07/schema",
  "type": "object",
  "required": ["name", "description", "tags", "spinnerVerbs"],
  "additionalProperties": false,
  "properties": {
    "name":        { "type": "string", "pattern": "^[a-z0-9-]+$", "minLength": 2, "maxLength": 40 },
    "description": { "type": "string", "minLength": 10, "maxLength": 200 },
    "tags":        { "type": "array", "items": { "type": "string", "pattern": "^[a-z0-9-]+$" }, "minItems": 1, "maxItems": 10 },
    "spinnerVerbs": {
      "type": "object",
      "required": ["mode", "verbs"],
      "additionalProperties": false,
      "properties": {
        "mode":  { "enum": ["replace", "append"] },
        "verbs": {
          "type": "array",
          "items": { "type": "string", "minLength": 1, "maxLength": 60 },
          "minItems": 10,
          "maxItems": 100,
          "uniqueItems": true
        }
      }
    }
  }
}
```

**Beyond-schema rules enforced by `validate-theme.sh`:**
1. Filename matches `name` field: `themes/cs/cimrman.json` must have `"name": "cimrman"`
2. Name uniqueness across all folders (prevents resolution ambiguity)
3. If file is in `themes/cs/`, tags must include `"cs"` (same rule for `sk`, `en`)
4. Files in `themes/community/` need at least 2 tags

## CI (`.github/workflows/ci.yml`)

```yaml
name: Validate themes
on:
  pull_request:
    paths: ['themes/**', 'schemas/**']
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm install -g ajv-cli ajv-formats
      - run: ./scripts/validate-theme.sh themes/**/*.json
```

`scripts/validate-theme.sh` calls `ajv validate` per file, then runs the custom beyond-schema rules. Exits non-zero on first failure with a readable message.

## Pull Request template

`.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## New spinner pack

**Name:** `<filename without .json>`
**Language/region:** `cs` / `sk` / `en` / `community`
**Short description (EN):**

### Checklist
- [ ] JSON in `themes/{locale}/<name>.json`
- [ ] 10–100 unique verbs
- [ ] Verbs stay in character (readers can guess the theme from 2 words)
- [ ] Tested locally: `./scripts/spinner.sh <name>`
- [ ] Tested locally: `./scripts/validate-theme.sh themes/**/<name>.json`

### Theme sample
Paste 3–5 representative verbs here:
```

## V1 content plan

**Packs included at launch:** `cimrman`, `pelisky` (Czech only, MVP).

**Curatorial criteria:**
1. **2-word test** — any random verb should suggest the theme within 2 words
2. **25–35 verbs per pack** (schema allows 10–100; this is the sweet spot)
3. **Form: 3rd person singular present** — `"Externě radí"`, not `"Externě radit"`; matches Czech dubbing conventions and Claude Code default verb style
4. **Max ~40 characters per verb** (terminal-safe)
5. **Unique**, no duplicates
6. **No politics, no slurs**
7. **Original content** — no copying from wynandw87 or cc-spinner

**Seed lists:** Drafted during brainstorm, to be finalized by the native-speaker curator (project owner) post-launch testing. Seed content stored in implementation plan, not fixed in this spec — content iteration is expected.

## Future (post-V1) roadmap

- **V1.1:** Auto-generate "Packs" table in README from theme metadata (`scripts/generate-readme-table.sh`, CI commit)
- **V2:** `SessionStart` hook as alternative to shell wrapper for autorotate (research timing guarantees first)
- **V2+:** Expand language coverage based on PR flow (SK, EN, DE, PL)
- **Stretch:** Webpage (like spinnerverbs.com) showing packs with preview, linking to install commands

## Launch checklist

- [ ] Repo `sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs` created, MIT license
- [ ] `.claude-plugin/plugin.json` + `commands/spinner.md` written
- [ ] `scripts/spinner.sh` functional for all 7 subcommands, manually tested end-to-end
- [ ] `schemas/theme.schema.json` + `scripts/validate-theme.sh` pass for both packs
- [ ] `themes/cs/cimrman.json` curator-finalized
- [ ] `themes/cs/pelisky.json` curator-finalized
- [ ] `themes/_template.json` written
- [ ] `README.md` (EN) with prominent "Featured: Czech & Slovak packs" section
- [ ] `CONTRIBUTING.md` with clear PR workflow
- [ ] `.github/workflows/ci.yml` passes
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` written
- [ ] Real-world test: apply both packs in own Claude Code; verify `random` + `install-autorotate` end-to-end
- [ ] PR to [awesome-claude-spinners](https://github.com/AlexPl292/awesome-claude-spinners) for visibility
- [ ] Posted to r/ClaudeAI, CZ/SK dev community channels

## Post-launch signals

- PRs for new packs → community is forming
- Issues "please add X theme" → desire for more first-party curation
- Stars after 2 weeks → interest baseline
- After 4 weeks: **0 PRs and <20 stars** → pivot; add more CZ/SK packs directly, push harder to Czech/Slovak dev scene (root.cz, Twitter/X, Discord)

## Credits & inspiration

- [AlexPl292/awesome-claude-spinners](https://github.com/AlexPl292/awesome-claude-spinners) — slash-command pattern, JSON-per-pack layout
- [Suntory-N-Water/cc-spinner](https://github.com/Suntory-N-Water/cc-spinner) — schema with `name`/`description`/`tags`
- [wynandw87/claude-code-spinner-verbs](https://github.com/wynandw87/claude-code-spinner-verbs) — proof that "massive verb inventory" has an audience
- [Boris Cherny](https://www.threads.com/@boris_cherny/post/DUoX-7iEgtC/) — official guidance on `spinnerVerbs` in `settings.json`

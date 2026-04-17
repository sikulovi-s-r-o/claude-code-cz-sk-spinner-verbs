# Contributing to Spinery

Thanks for the interest. Contributing a new spinner pack is straightforward — JSON file, 10–100 verbs, pull request. CI does the validation.

## Quick start (new pack)

1. **Fork & clone** this repo.
2. **Pick a locale folder**: `themes/cs/`, `themes/sk/`, `themes/en/`, or `themes/community/` (language-agnostic).
3. **Copy** `themes/_template.json` to `themes/<locale>/<your-name>.json`.
4. **Fill it in** — see [pack rules](#pack-rules) below.
5. **Validate locally** (see [local validation](#local-validation)).
6. **Open a PR** — the template will walk you through the checklist.

## Pack rules

| Field | Rule |
|---|---|
| `name` | lowercase, alphanumeric + hyphens, 2–40 chars, must match filename |
| `description` | English, 10–200 chars, one line |
| `tags` | 1–10 tags, lowercase + hyphens; locale folders (`cs`, `sk`, `en`) require the matching locale tag |
| `spinnerVerbs.mode` | `replace` (default) or `append` |
| `spinnerVerbs.verbs` | 10–100 unique strings, each 1–80 chars |

### Content guidance

- **2-word test** — a reader should guess the theme within 2 words of any random verb.
- **Form** — prefer 3rd person singular present tense matching Claude Code's default style (`Externě radí`, not `Externě radit`).
- **No politics, slurs, or attacks** on individuals or groups. Canon humor is welcome; punching down is not.
- **Originality** — don't copy existing packs from other repos wholesale. Inspiration fine; duplication not.

## Local validation

Install dependencies once:

```bash
brew install jq                         # macOS
sudo apt install jq                     # Debian/Ubuntu
npm install -g ajv-cli ajv-formats      # for schema validation
```

Then:

```bash
./scripts/validate-theme.sh themes/<locale>/<your-name>.json
./scripts/spinner.sh <your-name>        # optional: dry-run apply in a sandbox HOME
```

Running the validator without arguments checks every pack in the repo (recommended before PR).

## PR process

1. CI runs `validate-theme.sh` on all changed themes — it checks schema, filename match, locale tag, and global name uniqueness.
2. A maintainer reviews pack quality (2-word test, tone, originality).
3. Merged to `main`; next Spinery release includes your pack.

## Adding a new locale

If your language isn't under `themes/` yet:

1. Create the folder `themes/<iso-code>/`.
2. Add `<iso-code>` to `LOCALE_DIRS` in `scripts/validate-theme.sh`.
3. Put your pack inside. Include the ISO code as a tag.
4. Mention in the PR description so we document it in README.

## Bug reports & feature requests

Open an issue. For dispatcher bugs, paste the exact command you ran and your shell version (`bash --version`).

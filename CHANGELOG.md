# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6] — 2026-04-17

### Fixed
- `install-autorotate` shell wrapper is now path-independent. The
  block in `~/.zshrc` (or `~/.bashrc`) resolves the latest installed
  spinery cache at runtime instead of baking a versioned path in —
  rotation survives Claude Code plugin updates without user action.
- `scripts/validate-theme.sh` falls back to `npx` when `ajv-cli` is
  not globally installed, and replaces bash 4 `mapfile` with a
  portable `while read` loop so the validator works on macOS default
  bash 3.2.

### Changed
- Repository renamed to `sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs`
  for SEO + discoverability. Plugin name stays `spinery` (short slash
  command prefix preserved).

### Added
- `CHANGELOG.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- `.github/ISSUE_TEMPLATE/` — bug_report, feature_request, new_pack,
  and a config.yml redirecting common questions to README / CONTRIBUTING.
- README badges (CI, license, Claude Code version, packs count) and
  terminal-example snippet of the spinner in action.

### Removed
- `docs/IMPLEMENTATION_PLAN.md` (brainstorming artifact, not needed
  for public readers).

## [0.1.5] — 2026-04-17

### Added
- 7 race-specific Warcraft 3 packs split from the combined best-of:
  - `wc3-lide` (35 verbs), `wc3-orkove` (30), `wc3-nemrtvi` (33),
  - `wc3-elfove` (34), `wc3-nagove` (19), `wc3-hrdinove` (40),
  - `wc3-neutralni` (35).

### Changed
- `README.md` packs table grouped by locale with race-specific rows.

## [0.1.4] — 2026-04-17

### Added
- Expanded `warcraft-cz` to 50 verbs via Whisper transcription of the
  official Warcraft 3 CZ dub YouTube playlist.

## [0.1.3] — 2026-04-17

### Added
- `warcraft-cz` pack — 22 verbatim quotes from the legendary Czech
  dub of Warcraft III: Reign of Chaos.

## [0.1.2] — 2026-04-17

### Added
- `lakatos` pack — 30 verbatim quotes from the viral *Miluji svoji
  práci!* Lakatoš tractor repair meme, sourced from
  [milujipraci.cz](http://milujipraci.cz). Tagged `nsfw` + `adult`.

## [0.1.1] — 2026-04-17

### Changed
- Rewrote `cimrman` and `pelisky` packs as **verbatim quotes** instead
  of third-person paraphrases. A Czech reader recognizes the scene
  from the exact quote; the paraphrase form didn't trigger the memory.

## [0.1.0] — 2026-04-17

### Added
- Initial plugin scaffold, published under the `spinery` plugin name.
- Dynamic `/spinery:spinner <theme|sub>` slash command dispatcher.
- Subcommands: `<name>`, `list`, `status`, `random`, `off`,
  `install-autorotate`, `uninstall-autorotate`.
- Two seed CZ packs: `cimrman`, `pelisky`.
- JSON Schema + `scripts/validate-theme.sh` validator.
- GitHub Actions CI workflow validating every PR against the schema.
- Dispatcher honors `CLAUDE_CONFIG_DIR` env var so it writes where
  Claude Code reads (works with both native install and npm install).

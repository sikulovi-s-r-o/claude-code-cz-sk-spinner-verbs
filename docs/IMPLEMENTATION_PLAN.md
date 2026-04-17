# Implementation plan — v0.1.0

Build order for the MVP launch. See `DESIGN.md` for architecture rationale.

## Build order

1. **Scaffolding** — `LICENSE` (MIT), `.gitignore`, `.claude-plugin/plugin.json`
2. **Core logic** — `scripts/spinner.sh` with all 7 subcommands, atomic write, error handling
3. **Slash command bridge** — `commands/spinner.md`
4. **Contribution infra** — `schemas/theme.schema.json`, `scripts/validate-theme.sh`
5. **Seed content** — `themes/_template.json`, `themes/cs/cimrman.json`, `themes/cs/pelisky.json`
6. **CI + PR template** — `.github/workflows/ci.yml`, `.github/PULL_REQUEST_TEMPLATE.md`
7. **Public docs** — `README.md`, `CONTRIBUTING.md`
8. **End-to-end test** — install plugin locally, run all subcommands in live Claude Code session, verify:
   - `/spinner cimrman` applies verbs; `~/.claude/settings.json` shows `spinnerVerbs` block
   - `/spinner random` picks another theme
   - `/spinner list` enumerates both packs
   - `/spinner status` reports current theme
   - `/spinner off` cleans up
   - `/spinner install-autorotate` adds function to `~/.zshrc`, `~/.zshrc` sourced → wrapper kicks in
   - `/spinner uninstall-autorotate` removes cleanly
   - CI validates both packs locally (`./scripts/validate-theme.sh themes/**/*.json`)
9. **Initial commit** — single atomic commit of v0.1.0

## Deferred to v0.2+

- SessionStart hook as autorotate alternative (verify timing first)
- README auto-generation from theme metadata
- Additional seed packs (SK, EN, more CZ)
- Fish shell support in `install-autorotate`

## Known unknowns to verify during build

- **Claude Code plugin manifest schema** — is `"commands": ["./commands/spinner.md"]` correct, or does Claude Code auto-discover commands/ folder? Check current plugin docs before finalizing `plugin.json`.
- **Hot-reload behavior** — does a freshly-written `spinnerVerbs` take effect on next prompt, or require restart? Affects user-facing messages.
- **`${CLAUDE_PLUGIN_ROOT}` availability** — confirmed in Claude Code plugin docs; use in both `commands/spinner.md` (for script path) and in the autorotate shell function (for script path at runtime).

## Post-launch iteration

- Curator (project owner) refines seed verb content in `cimrman.json`, `pelisky.json` after real-world use
- Submit PR to `AlexPl292/awesome-claude-spinners` for discovery
- Post to CZ/SK dev communities (r/ClaudeAI, root.cz, Twitter/X)

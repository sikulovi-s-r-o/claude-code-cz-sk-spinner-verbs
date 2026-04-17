# Spinery — Spinner Packs for Claude Code

Curated spinner verb packs for Claude Code, with **first-class Czech & Slovak content** and community-driven coverage for every language.

```
✢ Externě radí… (12s · ↓ 224 tokens)
🎲 Peče kolínka… (4s · ↓ 512 tokens)
```

Instead of watching `Transmuting…` / `Cogitating…` for the hundredth time, let Claude Code speak your language, your humor, your culture.

## Features

- 🎭 **Curated themed packs** — quality over quantity, starting with Czech classics
- 🎲 **`/spinner random`** — surprise me each time
- 🔁 **`/spinner install-autorotate`** — new random theme on every `claude` start
- 📋 **`/spinner list` / `status` / `off`** — clean UX, zero magic
- 🧩 **Drop-in Claude Code plugin** — install, type `/spinner cimrman`, done
- 🔒 **Non-destructive** — never overwrites other keys in `~/.claude/settings.json`

## Installation

### As a Claude Code plugin (recommended)

```
/plugin marketplace add sikulam/spinery
/plugin install spinery
```

Then from any session:

```
/spinner cimrman
```

### Manually (no plugin)

Clone the repo and run the dispatcher directly:

```bash
git clone https://github.com/sikulam/spinery.git
cd spinery
./scripts/spinner.sh list
./scripts/spinner.sh cimrman
```

## Commands

| Command | Effect |
|---|---|
| `/spinner <name>` | Apply a theme (`cimrman`, `pelisky`, or `<locale>/<name>`) |
| `/spinner list` | List available themes with locale + verb count |
| `/spinner status` | Show currently applied theme |
| `/spinner random` | Pick a random theme and apply it |
| `/spinner off` | Remove `spinnerVerbs`, restore Claude Code defaults |
| `/spinner install-autorotate` | Add a shell wrapper that rotates the theme on every `claude` start |
| `/spinner uninstall-autorotate` | Remove the wrapper |

## Featured packs (Czech & Slovak)

| Pack | Locale | Verbs | Description |
|---|---|---|---|
| [cimrman](themes/cs/cimrman.json) | cs | 25 | Verbatim phrases and play titles from the Jára Cimrman theatre universe |
| [pelisky](themes/cs/pelisky.json) | cs | 25 | Verbatim quotes from the 1999 Czech film *Pelíšky* |
| [warcraft-cz](themes/cs/warcraft-cz.json) | cs | 50 | Verbatim quotes from the Czech dub of Warcraft III: Reign of Chaos |
| [lakatos](themes/cs/lakatos.json) | cs · **nsfw** | 30 | Verbatim quotes from the Lakatoš tractor repair meme — source: milujipraci.cz |

More CZ/SK packs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Packs tagged `nsfw` contain vulgar content suitable only for adult audiences.

## How it works

Claude Code 2.1.23+ reads spinner verbs from `~/.claude/settings.json` under the `spinnerVerbs` key. Spinery is a thin shell dispatcher wrapped in a Claude Code plugin — it reads a pack's JSON, merges `spinnerVerbs` into your settings (atomic write, preserves all other keys), and lets Claude Code pick it up on the next prompt.

See [docs/DESIGN.md](docs/DESIGN.md) for the full architecture and rationale.

## Autorotate variants

The default `/spinner install-autorotate` installs a shell function in `~/.zshrc` or `~/.bashrc` that rotates the theme each time you run `claude`. It's the most portable option.

Alternatives you can use manually (not installed by default):

- **Claude Code `SessionStart` hook** — runs `spinner.sh random` on session start. Requires Claude Code to pick up `spinnerVerbs` after hook execution; verify timing in your version. See `docs/DESIGN.md` for the research notes.
- **Cron / launchd job** — rotates every N hours regardless of `claude` invocations. Overkill for most; useful if you want fresh randomness between sessions on a long-running shell.
- **Curl-based one-shot installer** — if you don't want the plugin at all, `curl ... | bash` the dispatcher script. Not officially shipped yet.

Open an issue or PR if you'd like us to ship one of these as a first-class subcommand.

## Contributing

New pack ideas, additional languages, bug fixes — all welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the flow; contributions go through the standard PR → CI validation path, so it's hard to get it wrong.

## Credits & inspiration

- [AlexPl292/awesome-claude-spinners](https://github.com/AlexPl292/awesome-claude-spinners) — slash-command pattern, JSON-per-pack layout
- [Suntory-N-Water/cc-spinner](https://github.com/Suntory-N-Water/cc-spinner) — `name` / `description` / `tags` metadata schema
- [wynandw87/claude-code-spinner-verbs](https://github.com/wynandw87/claude-code-spinner-verbs) — proof that a large verb inventory has an audience
- [Boris Cherny](https://www.threads.com/@boris_cherny/post/DUoX-7iEgtC/) — official guidance on `spinnerVerbs`

## License

MIT — see [LICENSE](LICENSE).

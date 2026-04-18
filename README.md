# Spinery — Spinner Packs for Claude Code

[![CI](https://github.com/sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs/actions/workflows/ci.yml/badge.svg)](https://github.com/sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code 2.1.23+](https://img.shields.io/badge/Claude%20Code-2.1.23%2B-black.svg)](https://code.claude.com)
[![Packs: 13](https://img.shields.io/badge/packs-13-green.svg)](#featured-packs-czech--slovak)

Curated spinner verb packs for Claude Code, with **first-class Czech & Slovak content** and community-driven coverage for every language.

```
$ claude
› Kolik je 2+2?

  ✢ Externě radí…  (3s · ↓ 128 tokens)
  ✢ Patentuje jogurt…  (5s · ↓ 384 tokens)
  ✢ Překládá z češtiny do češtiny…  (8s · ↓ 642 tokens)

  4.
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
/plugin marketplace add sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs
/plugin install spinery@spinery
```

If your permissions policy makes `Bash` an `ask`-only tool (the default in many setups), add this line to your `~/.claude/settings.json` to stop the approval prompt on every `/spinery:spinner ...` invocation:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash *spinery*spinner.sh*)"
    ]
  }
}
```

Then from any session:

```
/spinery:spinner cimrman
```

### Manually (no plugin)

Clone the repo and run the dispatcher directly:

```bash
git clone https://github.com/sikulovi-s-r-o/claude-code-cz-sk-spinner-verbs.git
cd claude-code-cz-sk-spinner-verbs
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

### Culture
| Pack | Verbs | Description |
|---|---|---|
| [cimrman](themes/cs/cimrman.json) | 25 | Verbatim phrases and play titles from the Jára Cimrman theatre universe |
| [pelisky](themes/cs/pelisky.json) | 25 | Verbatim quotes from the 1999 Czech film *Pelíšky* |

### Warcraft III Czech dub (356 verbs total across all packs)
| Pack | Verbs | Description |
|---|---|---|
| [warcraft-cz](themes/cs/warcraft-cz.json) | 50 | Best-of mix across all Warcraft 3 factions |
| [wc3-lide](themes/cs/wc3-lide.json) | 35 | Human units (Peasant, Footman, Rifleman, Sorceress, …) |
| [wc3-orkove](themes/cs/wc3-orkove.json) | 30 | Orc units (Peon, Grunt, Troll, Wyvern rider) |
| [wc3-nemrtvi](themes/cs/wc3-nemrtvi.json) | 33 | Undead (Acolyte, Ghoul, Necromancer, Lich) |
| [wc3-elfove](themes/cs/wc3-elfove.json) | 34 | Night Elves (Huntress, Dryad, Druid, Demon Hunter) |
| [wc3-nagove](themes/cs/wc3-nagove.json) | 19 | Naga (Siren, Myrmidon, Royal Guard, Sea Witch) |
| [wc3-hrdinove](themes/cs/wc3-hrdinove.json) | 40 | Heroes (Arthas, Jaina, Thrall, Illidan, …) |
| [wc3-neutralni](themes/cs/wc3-neutralni.json) | 35 | Neutral units (Ogres, Bandits, Dark Ranger, Pit Lord) |

### Internet memes — **NSFW**
| Pack | Verbs | Description |
|---|---|---|
| [lakatos](themes/cs/lakatos.json) ⚠️ | 30 | Verbatim quotes from the viral "Miluji svoji práci!" Lakatoš tractor repair meme. Source: [milujipraci.cz](http://milujipraci.cz). |
| [brnensky-trener-best](themes/cs/brnensky-trener-best.json) ⚠️ | 54 | Best-of from the viral *Nasraný trenér dorostu z Brna* hockey-coach rant. Brno dialect highlights: *Pánové, já Vám na to seru*, *Budeš bydlet v tvarohárně*, *Rychle si odletím zpátky na Floridu*. |
| [brnensky-trener-full](themes/cs/brnensky-trener-full.json) ⚠️ | 93 | Full verbatim transcript of the same rant — the complete nutrition-and-discipline tirade for when one best-of isn't enough. |

More CZ/SK packs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

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

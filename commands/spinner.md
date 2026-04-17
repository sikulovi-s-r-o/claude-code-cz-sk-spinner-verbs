---
description: Apply, list, randomize, or remove Claude Code spinner verb packs
argument-hint: <theme-name> | list | status | random | off | install-autorotate | uninstall-autorotate
---

Run the spinery dispatcher with the user's arguments:

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/spinner.sh" $ARGUMENTS`

Relay the script's output to the user verbatim. Do not paraphrase, reformat, or add commentary. If the script exits with a non-zero status, show the stderr message as-is.

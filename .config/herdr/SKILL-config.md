---
name: herdr-config
description: "Configure Herdr itself — config.toml, themes, plugins, keybindings, notifications, saved machines, server lifecycle — or look up Herdr CLI syntax, concepts, and architecture. Use when the task is about Herdr's setup or documentation. Do not use for driving a live session; the herdr skill covers that."
---

# Herdr configuration reference

Herdr's full documentation set is linked into `references/` beside this file and tracks the installed version. This entrypoint is hand-maintained and stable; the references carry the version-specific detail.

List the directory, then read the file matching the task:

```bash
ls references/
```

Rough map — file names may shift between versions, so the listing wins:

| Task | Look in |
| --- | --- |
| config.toml keys, themes, defaults | config-reference, configuration |
| Workspaces, tabs, panes, agents, machines | concepts |
| CLI commands and flags | cli-reference |
| Keybindings | keyboard |
| Plugins | plugins |
| Saved SSH machines, remote control | persistence-remote |
| Session and state persistence | session-state |
| Socket/API automation | socket-api |
| Diagnosing a broken setup | troubleshooting |
| Scripting agents inside Herdr | agent-automation |

Prefer the reference over guessing keys or flags: Herdr's configuration surface is larger than the live-session skill describes.

This repo's Herdr config lives at `~/.config/herdr/config.toml`, with hand-maintained scripts under `~/.config/herdr/scripts/`.

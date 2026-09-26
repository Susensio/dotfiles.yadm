# Backlog

- tmux | tmux-notify: floating-pane notification tray and toasts for agents and bells.
  See `tmux/PROPOSAL-tmux-notify.md`.
- tmux | `PreToolUse` hook on `Bash` that blocks `tmux kill-server`/`kill-session`/`kill-window` when the command has no explicit `-L`/`-S`, message pointing at the `tmux-testing` skill's `scripts/tmux-test`.
  Prevents a bare destructive `tmux` command from silently falling through to the live default socket when hand-rolled `TMUX_TMPDIR` isolation resolves empty (happened in practice during tmux-uzi benchmarking: a cleanup command read an isolated socket path back from a file via `$(cat ...)`, the read failed silently, and `kill-server` hit the user's live session instead).
  `scripts/tmux-test` already prevents this for anything routed through it (`-L` on every call, refuses to kill a socket it did not create) — the gap is ad-hoc/scratch commands that skip the skill entirely because informal investigation doesn't feel like "testing."
  Get the pattern narrow enough to not false-positive on legitimate `-L`/`-S` usage.
  See `tmux-testing` skill's SKILL.md section 0 for the incident writeup.
- ci | Explore [Boeing/config-file-validator](https://github.com/Boeing/config-file-validator) to replace `json-syntax` and `toml-syntax`; held back for its small following (about 500 stars).
  v2.3.0 passed all 28 tracked config files, naming each, and covered what the one-liners do not: YAML, the `.jsonc`, `.editorconfig`, and the `##` alternates through `-type-map='**/*.toml##*:toml'`.
  Skip its `validate-configs-action` wrapper: it has no `type-map` input and only scans directories.
  CI could install it with `shfmt` through `jdx/mise-action`'s inline `mise_toml`; the Ubuntu runner already ships shellcheck, `jq` and Python.
- tmux | `just check` has no tmux config check.
  tmux 3.7c's `source-file -n` returned 0 for an unknown option and an unterminated quote, so a parse-only check caught nothing; a full load on a throwaway `-L` server caught the unknown option, but depends on the tmux version and Omarchy's palette, so it could only run locally, not on CI's Ubuntu tmux.
- harness | Harness testing/probing (`audit-harness`, verification subagents) should default to a lower-tier model, not Opus, for quota preservation.
  Most of what these probes do is mechanical verification (does a file exist, does a binding fire, does a check pass) rather than judgment calling for Opus-level reasoning.
  Where to state this is itself open: candidates are `audit-harness`'s own skill body (the moment this applies), or a model-selection note in `harness-design` under R-enforcement's "fastest/cheapest layer" framing.
  Decide the right slot per `harness-design`'s R-one-slot before writing it.
- claude | Check that `code-review-graph` is actually earning its keep once installed in a real project (maniac: `code-review-graph install --platform claude-code --no-instructions`, per-repo scope, hooks self-update the graph on Edit/Write and at pre-commit).
  `status`/`query`/`search` spot-checked clean against a known relationship at setup; still need `update --verify` for real (tiktoken-calibrated) token savings on that codebase rather than the README's benchmark numbers, and to watch whether Claude actually reaches for its skills (`detect_changes_tool`, `get_review_context_tool`, etc.) unprompted during a real review/explore/refactor/debug session.
  If it holds up, it's the harness's answer to "code-intelligence MCP server" for projects large enough to need blast-radius analysis (roughly maniac-sized, ~13k lines, not tmux-uzi-sized, ~3k) -- decide the general recommendation once this specific case has real signal.
- claude | Revisit adding Serena (LSP-based MCP server, symbol-aware find/read/edit) to a project once a concrete need shows up -- a safe cross-reference rename, `replace_symbol_body`-style precise edits, or wanting `ty` instead of `pyright` as the Python backend (Serena supports `python_ty` out of the box; Claude Code's native Python code-intelligence plugin is hardcoded to `pyright-langserver`, no swap mechanism).
  Claude Code's native LSP plugin already covers navigation/diagnostics for languages with a published plugin and an installed language server, so Serena's marginal value is specifically semantic *editing* and backend choice, not navigation -- don't add it preemptively, wait for the gap to actually bite.
  If added: register at local scope (`claude mcp add serena -s local -- serena start-mcp-server --context claude-code --project "$(pwd)"`), not `--scope user` (Serena's own docs default) or a manual JSON `.mcp.json` -- scoping it to the project avoids the bloat/noise its `activate`/`remind` hooks cause in non-coding sessions when registered globally (both are context-blind: `remind` counts grep/read calls with no check for an active Serena project, `activate` fires unconditionally on every `SessionStart`).
  Hand-add only the `remind`/`cleanup` hooks to that project's own `.claude/settings.json` (skip `activate`; skip `auto-approve` unless using `acceptEdits`/`auto` modes there).
  Skip the `--system-prompt` override entirely -- it's mostly a paraphrase of Claude Code's own default system prompt (duplicating/conflicting with existing instructions, including a stale hardcoded commit-attribution model name) with only the tool-selection section actually novel, and skip a `coding`-skill edit too, since the `remind` hook (once project-scoped) already does that job dynamically and correctly-scoped, unlike a global skill edit that would apply even in projects with no Serena registered.
- claude | `audit-harness` could mechanize ADR-0041's identity-only rule for a project's `CLAUDE.md` record-file lines — flag one that restates a boundary or edit/append rule instead of naming location/kind/writer only, rather than leaving the check to whoever next reads that `CLAUDE.md` under `project-docs` step 1.
  One incident (`maniac`'s 186-line `docs/STATE.md`) is not yet enough to justify building this; revisit if it recurs.

## Omarchy migration

- omarchy | Replace HEY as the desktop `mailto:` handler after the preinstall cleanup.
  Omarchy sets `HEY.desktop` unconditionally, while the cleanup removes its launcher; `omarchy-refresh-applications` can restore it.
  Test Gmail's Chromium protocol handler and desktop `mailto:` links on the laptop, then choose a user MIME association for bootstrap; a Gmail app shortcut alone does not handle `mailto:`.
- omarchy | Decide whether opening text files from the desktop should use Helix instead of Omarchy's `nvim.desktop` MIME defaults.
  Changing Omarchy's default editor updates its editor state, and our watcher updates `EDITOR`; neither changes MIME associations.
  Check the Helix desktop entry and `xdg-mime query default text/plain` on the laptop before adding a user override.
- mise | `tool upgrade`, `tool list --installed` and `tool show` still delegate only to mise, so they do not cover tools installed through pacman on Arch.
  Decide whether these commands should become source-aware, say explicitly that they are mise-only, or leave the wrapper in favor of native commands for those operations.
- env | uwsm's `mise activate bash --shims` (Omarchy's `/usr/share/uwsm/env.d/10-omarchy`) puts mise shims first on `PATH`, against ADR-0007; decide whether to accept or strip them.
- tmux | Decide whether to keep or locally override Omarchy's `omarchy-theme-set-tmux` after the Foot/tmux live checks in `docs/STATE.md`.
  It writes window styles before our hook does; a wrapper could prevent that but would also skip Gum environment, `COLORFGBG`, pane OSC, cursor fallback and redraw updates.
- mise | Once Omarchy PR #9596 (defaults as lazy shims in `/etc/mise/config.toml`) lands, revisit ADR-0007's symlinks versus mise shims, and `disable_tools` the unwanted Omarchy defaults.
- omarchy | `omarchy update` runs new `migrations/`, which edit tracked files in place: several append to or awk-filter `~/.config/tmux/tmux.conf`, one reseeds `herdr/config.toml`.
  Nothing blocks them; each update needs a `yadm diff` to revert or adopt what changed.
- env | `omarchy/editor.sh sync` copies only terminal editors into `EDITOR`; a GUI pick (`code`, `cursor`, `zeditor`, `sublime_text`) could be copied with its wait flag (`code --wait`, …) so git and `sudoedit` block on it.
  Undecided; it costs a per-editor flag map tied to Omarchy's menu list.
  Upstream has the same gap in `omarchy-launch-editor --inline` ([omarchy#13037](https://github.com/omacom/omarchy/issues/13037), fixes open in #13044 and #13094); once merged, the terminal-editor filter could go.
- omarchy | Track the Omarchy-seeded config on the laptop: `omarchy`, `hypr` and `foot` are already allowed in `yadm/exclude`; the other desktop dirs join the allowlist as they are adopted.
  Every one of them is a target of `omarchy update` migrations, so each widens the `yadm diff` review above.
- upstream | Omarchy: its AGENTS.md wrongly says `omarchy-pkg-add` handles the AUR.

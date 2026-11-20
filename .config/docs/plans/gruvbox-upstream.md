# Proposal: the Omarchy gruvbox and Helix theme upstream handoff

Status: in progress (started 2026-09-30, moved out of `docs/STATE.md` on 2026-11-20); the live status — which PRs are open, what is checked, what the local override currently does — stays in STATE, this file holds the roadmap and the decisions still to be made.
Goal: submit a faithful classic-gruvbox theme, improve the generic Helix fallback, and use Helix's bundled vendor themes where there is a defensible match.
These are separate contributions; the naming of stock `gruvbox` (currently gruvbox-material) is a related, potentially breaking decision, not an approved rename.
Do not treat a swap of the classic palette tiers as accepted; the vivid variants were tried and rejected.

## Completed upstream work

- Commented on [Helix template PR #6696](https://github.com/omacom/omarchy/pull/6696#issuecomment-5905412528): supported its semantic palette and contrast-safe transparent/inverted UI, asked whether removing `color0`–`color8` aliases should retain compatibility for custom themes inheriting `omarchy` or be called out as a migration, and noted that generic `bright_*` syntax defaults vary in contrast and meaning across themes.
  PR #6696 was open at the time of the comment; check its current status and responses before proposing template edits.
- Opened [Omarchy PR #13843](https://github.com/omacom/omarchy/pull/13843) (`Susensio:fix/helix-theme-link`, commit `1cc49b20`) for the Helix provisioning bug.
  It adds a one-time migration for already-installed Helix and provisions the link on future theme switches for Helix installed outside Omarchy's installer; both paths only create a missing `~/.config/helix/themes/omarchy.toml` if the rendered target exists, preserving existing files and even dangling custom symlinks.
  No dotfiles patch is required: it does not change the selected Helix theme or overwrite user config.
  Follow the PR to merge and test on update; if the rendered target is absent during its one-time migration, the next theme change will provision it.
  Do not apply the migration to the live machine just to exercise it.

## Current local experiment (not the intended upstream implementation)

- `omarchy/themes/gruvbox-classic/colors.toml` maps morhetz gruvbox's neutral hues to plain `red`…`cyan` and its actual bright hues to `bright_*`; background `#282828`, darker surfaces `#1d2021`/`#161616`, foreground `#ebdbb2`, accent `#fe8019`.
  **Do not swap tiers without a new decision**: that would change terminal ANSI 1–6 and throw away the faithful 0/1 gruvbox mapping.
  Omarchy's resolver forces `color7 = foreground`, so fully canonical ANSI white is not representable here; this is an accepted constraint to describe when proposing the theme, not a reason to reverse hue tiers.
  Decide explicitly whether the non-ANSI `orange` role should remain neutral `#d65d0e` or become vivid `#fe8019` for generated clients; avoid silently changing it.
- The scratch `gruvbox-vivid` and `gruvbox-vivid-flat` themes (bright tones in the plain slots) were tried and deleted on 2026-10-03.
  Against `terminal_color_0..15` in morhetz `colors/gruvbox.vim`, classic matches 14/16 slots (only 7 and 15, forced by the resolver to `foreground`/`bright_foreground`), vivid-flat 8/16, vivid 2/16.
  Swapping to vivid changed nothing visible in Herdr's `terminal` theme, whose greys come from slots 7 and 8, identical in all variants.
- `omarchy/themed/helix.toml.tpl` is a tracked local override with vivid syntax roles (`red_bright`, `green_bright`, etc.) and transparent `ui.background`.
  It was rendered and parsed without unresolved placeholders or Helix warnings, but it can wash out other themes whose bright roles are lighter tints and should **not** be submitted wholesale as a generic fallback.
  `helix/config.toml` selects `omarchy` (since 2026-10-21; before that `gruvbox_transparent`, a small overlay inheriting Helix's `gruvbox`); Herdr selects vendor `gruvbox`.
  The observed vendor theme preference and transparent Helix background should be preserved in later comparisons.

## Remaining contributions and decisions

1. **Classic gruvbox theme PR:** audit all current `gruvbox-classic` assets and compare the palette against morhetz gruvbox, terminal/Omarchy rendering, and vendor Helix before touching tiers; retain neutral→plain and bright→`bright_*` unless a specific counterexample justifies a change.
   The local theme presently has `backgrounds/`, `colors.toml`, `icons.theme`, and `neovim.lua`; a representative stock theme also ships `hyprland.lua`, `vscode.json`, `preview.png`, `preview-unlock.png`, and `unlock.png`.
   Verify which assets Omarchy actually requires before creating them, produce legitimate previews/background permissions, run upstream `./test/all` in a proper checkout, and provide before/after images for visual changes.
   Current stock `gruvbox` uses gruvbox-material colors but classic `ellisonleao/gruvbox.nvim`, so check Neovim integration for both themes.
   Posted [Suggestions Discussion #13864](https://github.com/omacom/omarchy/discussions/13864) (2026-09-30): option 1 adds `gruvbox-classic` beside unchanged `gruvbox`; option 2 renames stock to `gruvbox-material` with a `theme.name` migration and gives classic the short name (our lean).
   The editor-config mismatch (material palette, classic `neovim.lua`/`vscode.json`) was kept out of the discussion on purpose, as an implementation detail for the PR.
   Wait for a maintainer answer before implementing; do not bundle the rename without one.
2. **Better generic Helix fallback:** first follow [#6696](https://github.com/omacom/omarchy/pull/6696) and the review comment, and compare its result against the stock template and the local override across dark and light stock themes.
   The stock template largely uses only plain hues and collapses some syntax distinctions; #6696 names the palette semantically, adds bare `markup.heading`, moves constants to orange, and refines parameters/special roles.
   Do not open a competing change to the same file while that PR is live.
   Establish concrete remaining regressions with contrast and screenshots before a follow-up PR; bright roles are **not** universally safe as generic drawing roles (especially on light themes), and transparency plus legible statusline/menu must survive.
   The local override should eventually be revised or removed by explicit choice after testing the merged fallback; no local config rewrite was approved in the session that wrote this.
3. **Vendor-Helix `inherits` mapping:** the existing theme-staging/rendering path already honors a theme-shipped `helix.toml` ahead of `default/themed/helix.toml.tpl`.
   Propose a **Suggestions Discussion**, then a small PR with verified vendor-name overlays rather than copied full theme implementations; [closed PR #945](https://github.com/omacom/omarchy/pull/945) was rejected for maintaining full per-editor schemes, so explain how vendor inheritance reduces that burden, without assuming a maintainer will accept it.
   Candidate pairs to verify against the actual stock colors/backgrounds and installed Helix runtime: `gruvbox` (material)→`gruvbox-material`, `gruvbox-classic`→`gruvbox`, `catppuccin`→`catppuccin_mocha`, `catppuccin-latte`→`catppuccin_latte`, `everforest`→`everforest_dark`, `flexoki-light`→`flexoki_light`, `kanagawa`→`kanagawa`, `nord`→`nord`, `rose-pine`→`rose_pine_dawn`, `tokyo-night`→`tokyonight`; `ristretto`→`monokai_pro_ristretto` needs closer visual checking.
   Exclude generic lookalikes such as `white`→`emacs` or `vantablack`→`modus_vivendi` without a real brand match.
   Each overlay must include `"ui.background" = { }` beside `inherits = "…"`; shipping it suppresses fallback-template generation, and a bare inherit would lose Omarchy's transparency.
   Local proof (2026-10-03): `omarchy/themes/gruvbox-classic/helix.toml` ships `inherits = "gruvbox"` plus `"ui.background" = { }`; `omarchy-theme-set` copied it to the current theme verbatim, bypassing the local `helix.toml.tpl`. `helix/config.toml` now selects `omarchy`, so it shows live.
   Confirm Helix syntax and palette compatibility for each pair, test switching and cloning/staging, and re-evaluate if classic/stock gruvbox names change.

Upstream procedure: work in an Omarchy fork checkout, follow upstream `AGENTS.md` and `agents/skills/{migrations,install-scripts}.md` as applicable, run focused tests and `./test/all`, and keep upstream source edits out of `/usr/share/omarchy` and this dotfiles tree.
The local contribution guide still says `basecamp/omarchy`, while the live GitHub repository used for these PRs is `omacom/omarchy`; verify the live destination before filing.

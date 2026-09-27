# Past issues corpus (Susensio, github.com/hyprwm/Hyprland)

Repo-specific rules backing `../voice.md`, and the concrete authority for hyprwm/Hyprland specifically.
This repo takes **no issues**: reports are GitHub Discussions, and the body format is enforced by a bot.
Pulled via `gh api graphql` (discussions) and `gh api repos/hyprwm/Hyprland/contents/...`; re-run those rather than trusting this file as more current than the live repo.

## Policy: discussions only, mandatory format

- `.github/ISSUE_TEMPLATE/bug.yml` exists to refuse issues: its title is "Do not open issues, go to discussions please!" and its only required checkbox is "Yes, I want this issue to be closed."
  Never `gh issue create` here.
- The bug body layout is **not optional**, and `github-actions` closes a discussion that misses it with "This discussion has been automatically closed. Discussion format is NOT optional!", then posts `⚠️ Strike 1/3 issued to @Susensio by system.`
  Post through the web form for the category (`.github/DISCUSSION_TEMPLATE/<category>.yml`) instead of hand-writing the body.
- Required shape, from pinned #9853 ("[READ FIRST] Hi there! 👋"):

```
## Hyprland version
## Regression
## Describe the bug
## Reproduction steps
## System info and config
```

- `hyprctl systeminfo -c` goes in as an **attached file**, not pasted text.
- Check `hyprctl version`'s tag against the latest release before posting; the pinned guide asks you to update first if it lags.
- The bug form says "Please do **not** use AI to report bugs. Fill this report with your own words." and carries the required checkbox "I wrote this request with my own hands, my own keyboard, and in my own words."
  So an agent must not file here on the user's behalf: hand over the facts, let them write and post it.
- Category map that matters: Renderer explicitly owns "damage tracking (e.g. when parts of windows stay on the screen where they shouldn't and don't get updated)"; Window management owns windowrules and dispatchers; Config owns parsing, keywords and syntax; questions belong on forum.hypr.land.

## #16406 — Discussion: dim_around overlay stays over the gaps after unmaximizing (bot-closed)

Filed 2026-09-28 in `Bugs - Renderer`, closed within the minute for format, and cost strike 1/3.
Body was a custom layout with `## Hyprland version`, `## Describe the bug`, `## Steps to reproduce`, `## Workaround`, `## Related` — close to, but not, the required headings, which is enough for the bot to close it.

What the report was for, worth restating if it is refiled by hand:

- A window rule `{ fullscreen_state_internal = 1 } -> { dim_around = true }` leaves the gaps dimmed after `hl.dsp.window.fullscreen({ mode = "maximized" })` is toggled off, until any later damage event.
  `hyprctl getprop <addr> dim_around` reads `false` immediately, so the value is gone and only the pixels linger.
- Moving the cursor out of the window clears it, and so does a screenshot: `grim` forces a render, which is why the bug cannot be captured in an image.
- `debug:damage_tracking = 1` hides it, pointing at the damaged regions rather than the rule.
- Adjacent, not duplicate: [#14558](https://github.com/hyprwm/Hyprland/discussions/14558) covers `decoration:` values not being re-applied to existing windows after a runtime change, traced there to 0.55.0's `propRefresher`.

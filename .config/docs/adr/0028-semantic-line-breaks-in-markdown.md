# ADR-0028: Break markdown prose by sentence instead of hard wrapping

Status: Accepted
Date: 2026-08-19

## Context

The repo's markdown had no declared line-break convention and had drifted into two.
Forty of forty-five harness and doc files were hard wrapped near 80 columns; `GLOBAL.md`, the `git-commit` skill and parts of the `adr` skill ran one long line per paragraph, and `ENVIRONMENT_ARCHITECTURE.md` did too.
Nothing recorded which was intended, so each edit picked whichever the surrounding file happened to use.

The cost falls on review rather than reading.
Prose here is edited constantly, often by an agent, and a hard-wrapped paragraph cannot be edited without rewrapping it: changing one word reflows every line after it, so the diff shows a rewritten block and neither a human nor a reviewing agent can see which sentence actually changed.
Two conventions in one tree makes it worse — the same paragraph gets rewrapped to a different width by whoever touches it next.

Three options were weighed.
**Hard wrap at 80** was the incumbent and matched most files, and it is what an editor with soft-wrap off wants; it keeps the rewrap-churn problem, which is the actual defect.
**No wrapping at all** — one line per paragraph — removes the churn, but a changed word still produces a whole-paragraph diff line, and it is unreadable without editor support.
**Semantic line breaks** — one sentence per line — remove the churn and localize a diff to the sentence that changed, at the cost of lines that exceed any viewport.

Helix, the editor in use ([ADR-0008](0008-replace-neovim-with-helix.md)), defaults `soft-wrap` off, which is what made hard wrapping look mandatory rather than chosen.
It is one per-language setting, not a constraint.

## Decision

Markdown prose breaks at sentence boundaries — one sentence per line, never wrapped to a column — with YAML frontmatter, fenced code, tables and headings left verbatim, and `soft-wrap` enabled for markdown in helix so the long lines stay readable.

The rule as current practice lives in `agents/skills/audit-harness/design-rules.md` as R2, enforced by a check in the audit beside it, with the always-loaded instruction in `GLOBAL.md`.
That split follows [ADR-0026](0026-harness-content-by-tier.md): this record is the decision at a moment and does not change, `design-rules.md` is the policy that gets edited.
Being a user-tier rule, R2 yields to a repo whose tracked markdown already holds to another convention.

## Consequences

A one-word edit now shows as a one-line diff, so review sees which sentence changed instead of a rewritten paragraph, and there is one convention for an agent to follow rather than a coin flip per file.
Applying it was mechanical and safe: all fifty converted files verify word-for-word identical to their previous content under a whitespace-normalized diff.

Costs: a one-time reflow of every markdown file in the repo, which churns `git blame` on twenty-six accepted ADRs that were not otherwise being touched.
Long sentences now exceed any terminal width, so reading them depends on an editor setting — anything that views these files without soft-wrap (a pager, a diff in a narrow pane, a web view) scrolls sideways.
Sentence boundaries are a judgment an author has to make, and the audit check can only spot the obvious violations — a line holding two sentences, or a sentence continued onto the next line — so the convention is a discipline with a compensating control, not a formatter.

`keybinds/helix.md` is deliberately exempt: it is upstream Helix documentation copied in, and rewrapping it would impose this repo's convention on someone else's text and make future re-syncs diff noisily.

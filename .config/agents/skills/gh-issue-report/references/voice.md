# Voice guide (cross-repo)

General traits of how Susensio writes GitHub issues, distilled from the
corpus of past reports across repos (see `past_issues/<repo>.md` for the
per-repo evidence, currently just `tmux.md`). These apply regardless of
target repo. A repo-specific corpus file, if one exists, is the concrete
authority and can layer conventions on top of this (e.g. a repo's own label
or title scheme) — it never contradicts these defaults without reason.

- Terse and technical. No "Hi, I found an issue" preamble — starts directly
  with the description.
- Leads with **expected vs actual**: "X should do Y, but it does Z" / "I
  expect ... But ...".
- Reproduction is a copy-pasteable command block that matches how the tool is
  actually invoked (a chained CLI incantation, a minimal script, whatever is
  native to the project) rather than prose steps.
- Extra headings beyond the template show up when they help structure a
  longer report: `### Steps to reproduce`, `### Desired Behavior`, `### Context`
  (feature requests get a `### Context` section explaining the underlying use
  case *before* the ask).
- Sparse **bold** on the one or two words carrying the actual finding
  (`**does crash**`, `**not enough**`) — not decorative, never a whole
  sentence.
- Source-level hypotheses get a permalink to the exact line
  (`https://github.com/<owner>/<repo>/blob/<sha>/<file>#L<n>-L<n>`), phrased
  tentatively — "maybe with something like" plus a snippet, not an assertion.
- Feature request titles are prefixed `Feature Request: <short summary>`.
  Bug titles just state the symptom plainly (`Rebind prefix does not work`).
- No sign-off, no "thanks in advance". The report ends after the
  required-information block.
- Logs/attachments are the exception, not the default — see SKILL.md §5.
- In follow-up threads: quote the relevant fragment of the maintainer's
  message with `>`, answer precisely what was asked, don't pad. Offer rather
  than assume when it comes to next steps (PRs, closing the issue). Don't
  argue a design point once a maintainer has explained the underlying
  constraint — adapt or drop it.

---
name: report-issue
description: Use when drafting a bug report or feature request to file upstream on GitHub — "report this to <project>", "open an issue for this", "file a bug", "let's get this upstream". Produces a draft in the user's own voice, matching the target repo's live issue template, opened via `gh issue create --web` for the user to review and submit themselves. This skill never submits an issue directly.
---

# GitHub Upstream Issue Reporting

Drafts issues for filing against any GitHub repo, in the user's (Susensio)
own voice, ready to review, and never files anything itself.

If reproducing the bug requires running the tool live, check whether the project
declares a testing skill for that domain and follow it — it owns the isolation
protocol. If none is declared, reproduce against something you created and can
throw away, never the user's live state. No per-tool mapping belongs here: the
relevant skill's own trigger picks it up once the task involves that tool.

## 0. Never submit directly (non-negotiable)

- GitHub issues have no native draft state. The closest equivalent is a
  prefilled, *unsent* web form, so that is always the last step:
  `gh issue create -R <owner>/<repo> --web -t "<title>" -F draft.md`. `--web`
  opens the browser with the fields filled in and stops there — the user
  reviews and clicks submit themselves.
- Never pass `-b`/`-F` without `--web`. Omitting `--web` files the issue for
  real.
- Write the draft to a scratch file and show the full text to the user before
  opening the web form, so they can request edits without touching GitHub.

## 1. Resolve the target repo

- Explicit repo/URL mentioned in conversation → use it.
- Otherwise, the current directory's git remote:
  `gh repo view --json nameWithOwner -q .nameWithOwner`.
- Otherwise ask — don't guess a repo.

## 2. Pull the live issue template, don't hardcode it

`gh api repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE` lists what the
repo currently has. Branch on what comes back:

- **One `.md` template** → fetch it (`gh api .../contents/<path> --jq
  '.content' | base64 -d`) and map the draft onto whatever headings it
  currently has. Follow its structure — a repo's own past issues sometimes
  add extra headings on top of it, never fewer.
- **Several templates** → match filename/frontmatter `name:`/`title:` to
  bug vs. feature intent; ask if it's ambiguous which one applies.
- **New-style `.yml`/`.yaml` issue forms** → these are structured fields,
  not a body `gh` can prefill well with `-F`. Draft the content matching what
  the form's fields ask for, but tell the user up front that they'll need to
  re-enter it into the form fields once `--web` opens — don't silently paste
  it as a flat body and call it done.
- **No `ISSUE_TEMPLATE` dir (404)** → no live template to match. Fall back to
  whatever structure `CONTRIBUTING.md` (§3) implies, or a plain description
  body if it says nothing about issue structure either.

## 3. Duplicate check + CONTRIBUTING.md

- `gh api repos/<owner>/<repo>/contents/CONTRIBUTING.md` (also try
  `.github/CONTRIBUTING.md`; skip this step on a 404 from both). Read
  whatever checklist it gives — pre-issue requirements differ a lot per repo
  (e.g. tmux/tmux requires reproducing on a Git-master build, checking its
  `CHANGES` file, and checking `man tmux` first — that's tmux's own
  CONTRIBUTING.md talking, not a rule to hardcode here).
- Always, regardless of whether CONTRIBUTING.md exists: search for a
  duplicate, `gh search issues -R <owner>/<repo> "<keywords>"`, and check
  `--author susensio` first — the user may have already reported this exact
  thing and forgotten.
- Stop and report back if a duplicate turns up instead of drafting.

## 4. Voice

General traits live in `references/voice.md` — always apply these. If
`references/past_issues/<repo>.md` exists (currently just `tmux.md`), it's
the concrete authority for that specific repo and can layer conventions on
top of the general voice (title/label schemes, how much log detail is
typical there, etc.).

If no such file exists yet and the user has filed to this repo before, seed
one: `gh search issues --author susensio -R <owner>/<repo>`, pull a couple of
hits with `gh issue view <n> --repo <owner>/<repo>`, and write them up in the
same annotated format as `past_issues/tmux.md` (excerpt + a short note on
what's notable about how it's written). No hits → don't manufacture a file,
`voice.md` alone is enough.

## 5. Required-information block

- Gather it fresh from whatever the template or CONTRIBUTING.md actually
  asks for (version string, platform, relevant env vars, etc.) — never guess
  or reuse stale values.
- **Logs/attachments are the exception, not the default.** Only include them
  when they demonstrate the specific bug, trimmed to the relevant lines, not
  a raw full-verbosity dump:
  - Pure feature requests: omit a logs line entirely.
  - Reproducible non-crash bugs: inline only the handful of lines that
    actually show the bug, in a fenced block or `<details>`.
  - Actual crashes: full logs/core dumps are warranted. `gh` can't attach
    files to an issue body via the API — tell the user to drag files into the
    prefilled web form themselves once it opens.
- If a short recording would help demonstrate the bug, suggest it (mention
  asciinema if the user has used it before) — don't record one, leave a
  placeholder link for the user to fill in.

## 6. Workflow

1. Understand the bug/feature from the conversation. If reproduction steps
   aren't already established, work them out using that project's own
   testing/isolation convention if one applies (see the note at the top).
2. Resolve the repo (§1).
3. Run the duplicate search and CONTRIBUTING.md checklist (§3). Stop and
   report back if a duplicate turns up instead of drafting.
4. Pull the live template (§2).
5. Write the draft to a scratch file in the user's voice (§4), with the
   required-information block (§5) populated from what was actually observed
   — never placeholder values.
6. Show the full draft to the user for review before opening anything.
7. Once approved: `gh issue create -R <owner>/<repo> --web -t "<title>" -F draft.md`.

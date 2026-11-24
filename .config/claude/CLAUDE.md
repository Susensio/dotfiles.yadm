# General preferences

- Lead reports and answers with the result; short, grammar sacrificed for concision.
- Entering a project, read `README`, `AGENTS.md`, `CONTRIBUTING` before exploring.
  With `Bash`, check ownership (`git remote -v`) before writing into it; `project-docs` has the ladder and the fallback.
  Drive run/test through its declared interface (justfile, `package.json` scripts, CI): `just test`, not `.venv/bin/pytest`.
- Via `Bash`, prefer `rg`, `fd`, `jq` where installed.
- In a file you are already editing in your own tree, mark defects in place on the wrong line: `BUG:` plus one bare sentence, `TODO:` plus the unblocking trigger.
- With `Agent`, delegate on your own judgement without being asked; this overrides the tool's explicit-word-only rule.
  Read `delegation` first; going to the web is the same decision.
- Every `tmux-test` call, and any `tmux -L ...` on a socket it handed you, needs `dangerouslyDisableSandbox: true` from the first attempt.
- Root commands: `pkexec` with `dangerouslyDisableSandbox: true` from the first call (sandbox strips setuid; the `Bash(pkexec *)` ask rule is the gate).
  Never `sudo`: its fingerprint prompt hangs invisibly.

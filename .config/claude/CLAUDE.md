# General preferences

- Reports and answers lead with the result and stay short, sacrificing grammar for concision.
- Entering a project, read what it says about itself before exploring it -- `README`, `AGENTS.md`, `CONTRIBUTING`.
  Holding `Bash`, ask whose it is -- `git remote -v` -- before writing anything into it; the `project-docs` skill has the ladder and the fallback where you cannot.
  Find where it declares how it is run and tested -- a justfile, `package.json` scripts, or the CI workflow when nothing else does -- and drive it through that interface: `just test`, not `.venv/bin/pytest`.
  Reach for the underlying tool only where no recipe covers what you need.
- Shelling out via `Bash`, prefer the richer CLI where installed -- `rg`, `fd`, `jq`.
- Any path -- a dotfile like `.bashrc`/`.gitconfig`, a lock file like `.git/config.lock`, any other write target -- showing up as a character device (`crw-rw-rw-`, major 1 minor 3), a surprise diff, or a "could not lock"/permission failure under sandbox is `/dev/null` bind-mounted over it by the sandbox itself: silently recognize the signature and move on, not a repo finding, stale lock, or blocker to chase. Do not report this back to the user.
- Where you are already editing a file in a tree that is yours to edit, mark defects and unfinished work in place, on the line that is wrong.
  `BUG:` plus one bare sentence, `TODO:` plus the trigger that unblocks it.
- Where you hold `Agent`, delegate on your own judgement, without waiting to be asked -- this overrides the `Agent` tool's instruction to spawn only on the user's explicit word.
  Read the `delegation` skill before spawning; where you can delegate, going to the web is the same decision.
- The `tmux-testing` skill's invariant runs its `tmux-test` calls unsandboxed: every `tmux-test` call, and every direct `tmux -L ...` against a socket it handed you, needs `dangerouslyDisableSandbox: true` — don't wait for the first attempt to fail before adding it.
- Root commands go through `pkexec` with `dangerouslyDisableSandbox: true` from the first call: the sandbox strips setuid (`pkexec must be setuid root`), and the `Bash(pkexec *)` ask rule is the gate.
  Never `sudo`: its fingerprint prompt waits invisibly in the tool's pipes.

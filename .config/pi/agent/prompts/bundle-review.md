---
description: Review the extension bundler — gates, hazards, verdicts, and whether each bundle is worth its risk
argument-hint: "[package]"
---
Review the extension bundles in `~/.config/pi/agent/bundler/` (ADR-0067) and report what should change. `${1:-}` narrows the review to one package when given.

Every bundle is a risk that module loading behaves differently from source, and no gate proves otherwise, so the question for each package is whether its measured saving is worth that risk.

## Gather

1. `node ~/.config/pi/agent/bundler/screen.mjs` — gate, decision, module count, and hazard lines per package. Exit 1 means a verdict is missing or stale; the printed `reviewedKinds` is the observed set.
2. `node ~/.config/pi/agent/bundler/benchmark.mjs 5` with the bundles in place; keep the per-package medians.
3. `node ~/.config/pi/agent/bundler/bundle.mjs --revert`, then the benchmark again for the source medians.
4. `~/.config/pi/agent/bundler/run.sh` to rebundle, and confirm with `screen.mjs` that every package is back to its earlier state. Never leave the tree reverted.

Numbers move with machine load; compare the two passes run back to back, never against ADR-0067's figures.

## Judge each package

- **Saving**: source median minus bundled median. Under ~100 ms is not worth a bundle; recommend a `skip` verdict saying so.
- **Hazards** (gate B): for every hit, read the flagged line and enough of its surroundings to say whether a relocated file changes what it resolves. A bare package specifier survives relocation; a path built from `import.meta.url`, `__dirname`, or `createRequire` that points at a sibling file does not. Quote the line that proves the verdict.
- **Missing verdicts**: packages bundled only because they screened clean have never been read. Say so, and judge whether their saving earns a verdict or a `skip`.
- **Stale verdicts**: a `reason` that no longer matches the code, `reviewedKinds` that differ from the screen's, or a `reopenIf` condition that has come true.
- **Gate C / refused packages**: say whether the refusal still holds; a new upstream release may have removed the cycle.
- **Behaviour**: for each bundle you keep, name one thing its extension does on first use (a tool call, a command, a lazily loaded UI) that module loading could break, and how to try it by hand. Do not attach to a live session to try it.

## Report

A table: package, gate, modules, source ms, bundled ms, saving, current decision, recommended decision.
Then the proposed `verdicts.json` diff with a one-line reason per change, and the hand-test list.
Uncertain calls go to the user, not the diff. Wait for confirmation before editing `verdicts.json` or rebundling.

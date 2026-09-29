# ADR-0067: Replace screened pi extension sources with prebuilt esbuild bundles from a postinstall hook, instead of forking each heavy package or waiting for upstream to bundle extensions

Status: Accepted
Date: 2026-09-28

## Context

Pi loads every extension through `jiti`, module by module, during startup.
Interactive launch took ~3.2 s, and ~2.4 s of it was extension loading: with `--no-extensions` the same start took ~0.73 s, and the startup profiler behind `PI_TIMING=1` attributed essentially nothing else to it (session manager 2 ms, theme 8 ms, model scope 0 ms).

The cost was per module, not per package.
A synthetic extension of 120 trivial modules cost ~1.7 s, while the same code as a single file cost ~0.18 s.
Pi packages ship TypeScript sources, so the heaviest graphs were also the largest: `pi-footer` imported 119 modules in ~900 ms, `@tintinweb/pi-subagents` 932, `pi-claude-bridge` 631.

`jiti`'s filesystem cache was already doing its job — it stores transpiled output under `os.tmpdir()/jiti`, and a cleared cache made a first start cost 9.5 s against a warm 3.2 s — so what remained was module-by-module load overhead of roughly 8–14 ms per module, cache hit or not.

Alternatives were weighed.
Dropping extensions gives the time back but loses the features.
Forking each heavy package has precedent ([ADR-0064](0064-vendor-sticky-last-prompt.md)) but means owning a fork per package against upstream drift.
Vendoring each bundle as a local package was already rejected on adjacent ground in [ADR-0062](0062-session-naming-in-own-extension.md) for taking package management away from `pi update`.
Moving `TMPDIR` so `jiti`'s cache survives reboot removes only the post-reboot penalty, leaves the steady-state cost, and changes a global environment variable for every program.
Waiting for upstream to compile or bundle extensions carries no ship date.

Bundling is not uniformly safe, and the failure mode decides the design.
esbuild cannot resolve some packages at all: `@gotgenes/pi-permission-system` and `@mzwing/pi-permission-auto-review` use `#src/*` subpath imports whose mapped targets esbuild will not resolve.
`@latentminds/pi-quotas` imports the pre-rename `@mariozechner/*` names, which pi aliases at runtime; those are externalized alongside `@earendil-works/*` and the package builds, so it is not a gate-A case — an earlier draft of this record said otherwise on the strength of a probe that omitted that external.
More seriously, inlining relocates a module, so any code that locates a sibling asset through `import.meta.url` silently starts looking in the wrong directory: `pi-claude-bridge` inlines `@anthropic-ai/claude-agent-sdk`, which resolves its native CLI that way and throws `Native CLI binary for <platform>-<arch> not found` once moved.

## Decision

A tracked library lives beside the patch library at `agent/bundler/`: `lib.mjs`, `screen.mjs`, `bundle.mjs`, `verdicts.json`, `run.sh`, and `benchmark.mjs`.

`screen.mjs` classifies every package in `settings.json` through four gates and fails closed.
Gate P refuses any package named by a `patches/*/target`, because a bundle would shadow the patched source and the patch would land in a file nobody loads.
Gate A refuses any package esbuild cannot resolve, which is a proof rather than a judgement.
Gate C refuses any package whose built bundle has async module initializers that await each other, which would deadlock; it is also a proof, so it runs ahead of the verdicts and no verdict can override it.
Gate B scans the esbuild metafile's inlined-module list — only what is actually inlined, not the whole package — for `import.meta.url`, `import.meta.dirname`/`filename`, `__dirname`/`__filename`, `createRequire`, quoted `.wasm` and `.node` assets, and `new Worker`, and requires a verdict recorded in `verdicts.json` for every hit.
A verdict carries a `reviewedKinds` list, so a change in the detected set re-opens it and a dependency bump cannot ride on an approval granted for a different graph.

Six packages carry a `bundle` verdict and three do not, and gate C refuses one of the six, `@juicesharp/rpiv-ask-user-question`, as described under Consequences.
`@gotgenes/pi-permission-system` is the patch target of [ADR-0066](0066-trust-auto-reviewer-external-directory.md) and also fails gate A; `@mzwing/pi-permission-auto-review` fails gate A; `pi-claude-bridge` was refused because its hazard is fatal when inlined and externalizing the SDK was measured at ~390 ms against ~590 ms for source, which does not buy the upkeep.
The one patched package is also unbundleable, so gate P costs nothing today.

`bundle.mjs` runs esbuild once per verdict with the packages pi supplies as virtual modules external — `@earendil-works/*` and the pre-rename `@mariozechner/*` alias — and then rewrites that package's own `pi.extensions` field to point at `./.pi-bundler/bundle.mjs`.
Pi reads that field from the package's `package.json` on every start, so repointing it is the whole mechanism.
All state it writes — the bundle, the pristine manifest backup, the metafile, and an `owner` marker — lives in `<pkg>/.pi-bundler/`, so reverting restores the manifest and removes only that directory.
The marker, or a manifest that points at our bundle, is what establishes that the directory is ours to remove: a package that happened to ship its own `.pi-bundler` is left alone.
An earlier revision wrote its bundle to `<pkg>/dist/` and reverted with `rm -rf <pkg>/dist`, which destroyed the upstream source of `@narumitw/pi-usage`, whose declared entry *is* `./dist/index.ts`; the rule that follows is that the tool may only ever delete a directory it created itself.

Ordering composes with the patch library rather than fighting it: patches run first, bundling runs second, so a bundle carries whatever the patches changed.
`apply.sh`'s drift detection is untouched because `src/` is never written.

`run.sh` is the postinstall entry point in the [ADR-0057](0057-omarchy-bugfix-patch-steps.md) and ADR-0066 shape: silent when nothing changed, never failing an install.
The gate lives inside `bundle.mjs`, which runs `screen.mjs` itself and refuses to touch `node_modules` when the screen is unhappy.
Putting it there rather than in the shell wrapper is the point: invoked directly, `bundle.mjs` cannot skip the gate.
The lock it takes excludes other bundler runs, so the graph cannot change between screening and building *among those*; it does not exclude a concurrent `npm install` replacing a package in that window, which on this machine would require two pi processes installing at once.
An earlier revision had `run.sh` screen and then call the bundler, which left the gate skippable and left a window between the two steps.

What the gate decides is what gets bundled.
`bundle.mjs` builds every package the screen reports as `bundle` rather than every package with a hand-written verdict, so a newly installed extension with no hazard is screened, approved, and bundled without anyone editing a file.
It also restores any bundled package the screen no longer approves, so a bundle built under an earlier screen does not outlive a later refusal.

`verdicts.json` is the decision record rather than a cache, and it carries more than a yes/no.
`reviewedKinds` lists each hazard as `file:kind×count`, so a new hit of a known kind in a known file re-opens the verdict rather than passing as one of the old ones.
`reopenIf.installed` names packages whose absence is what makes a hazard inert — the two `rpiv` verdicts depend on `@juicesharp/rpiv-i18n` not being installed — so that condition is checked mechanically instead of being a sentence in a reason field nobody re-reads.

A package reaches the screen's own sources, not its artifact: once a bundle is applied the installed manifest names the bundle, so `packageEntries` prefers the kept pristine manifest when one exists.
Without that, a re-run would screen the bundle (one module, no source hazards) and every recorded verdict would look stale.

Reverting does not depend on `verdicts.json` still naming a package: it also sweeps `node_modules` for stray state directories, a manifest that points at a bundle with no pristine copy left is reported as stuck rather than as already-clean, and verdict keys are validated as package names before any package directory is written.
Concurrent runs take a lock with a staleness window, because the postinstall hook and a hand-run can otherwise interleave.

## Consequences

Measured in a single pass over five runs per state, to control for drift: median startup went from 1732 ms to 952 ms wall clock, and from 1427 ms to 634 ms on the startup profiler's own total.
What was removed was the per-module cost; the remaining ~0.6 s is mostly the cost of starting pi at all.
The absolute figures move with machine load — repeated passes during this work put the source state anywhere from 2226 ms to 3183 ms wall — so the ratio, consistently between 1.8x and 2.0x, is the durable number rather than any single pair.

Correctness was checked as the same extension set rather than the same speed: all 14 extensions load in both states with no load errors, the `/` menu advertises 51 commands in both, the session transcript records the same 10 tools in both, and the custom statusline still renders.

The hook line in the pi-owned `npm/package.json` is injected by the pi bootstrap step, which builds it from whichever halves exist and runs both in the same order, so a checkout carrying only the patch library still installs cleanly.
Running that step by hand to wire the bundler also reported `applied` for the ADR-0066 patch rather than `already applied`, so the patch had lapsed at some point between installs — the failure mode that record predicted.
It is repaired now, but it shows the shape of the risk: a hook only fires on an install or a bootstrap, so anything it maintains can lapse silently in between.

The failure direction is deliberate: un-wired, un-screened, or unresolvable-esbuild all degrade to the slow path, never to a broken one.

An independent review of the first working revision found that the gate was not on the automatic path after all — `run.sh` bundled without consulting the screen, so the fail-closed property held only for a hand-run — and that revert coverage was coupled to `verdicts.json` still naming the package.
A second found that the decision record and the screen's header claimed hazard-free packages bundle without a verdict while nothing implemented it, because the build loop read only `verdicts.json`; the fix is the report-driven loop described above.
A third found that the bootstrap step guarded the hook it writes but not the two halves it then ran, so a checkout with only one half aborted the whole bootstrap on a missing file, and that this record's gate-A rationale for `@latentminds/pi-quotas` was false.
All three confirmed that no code path could delete a file the tool did not create, and that the six `bundle` verdicts were justified by evidence on disk.

One of those six was not safe, and none of the original three gates could have caught it.
`@juicesharp/rpiv-ask-user-question` lazily imports its questionnaire graph, and that graph contains top-level `await`, so esbuild wraps each module in an async initializer.
`view/dialog-builder.ts` and `view/tab-content-strategy.ts` import each other, so each one awaits the other's pending initializer.
The first `ask_user_question` call in every bundled session then never resolved: no questionnaire appeared, the session showed "Working...", and Esc could not cancel because the tool ignores the abort signal.
Gate C was added for this case, and the bundler's restore step followed because the gate alone would have left the existing broken bundle in place.
The package keeps its `bundle` verdict, so it bundles again automatically once an upstream release breaks the cycle.
The detector parses esbuild's `var init_x = __esm(...)` output shape, so an esbuild release that renames those wrappers would make it see nothing and pass everything; a known-cycle probe would catch that, and none is run.

Accepted limitations:

- A package with no hazard, that esbuild resolves, and that no patch targets needs no verdict and is bundled automatically. The screen's "clean" means "none of the seven scanned constructs are present", not "provably safe": a hazard reached through an alias or a pooled-worker library is outside what the scan can see. This is also the one path where a package is bundled without a human having read anything about it.
- The lock that serializes runs is stolen only from a dead holder, but a run that dies inside the window can still leave tool-owned state to unwind by hand.
- A bundle is a build artifact, not reviewed code. A dependency bump changes the inlined code with no diff to read, and `reviewedKinds` re-opens review only when the scanned hazard set changes, not when behaviour does.
- `pi update` replaces a package directory wholesale, discarding both the bundle and the manifest backup. The package returns to source and stays there until the hook runs again, so a lapsed hook costs speed, not correctness. The same install discards the patch library's work, which is why the two share one hook rather than two.
- Bundles are not source-mapped, so a stack trace from a bundled extension points into `.pi-bundler/bundle.mjs`.
- esbuild is not installed by pi and must be resolvable when the hook runs; the library reports its absence and skips rather than building something stale.
- A freshly built bundle has no `jiti` cache entry, so the first start after a build pays it once (~5.4 s observed). That cache lives in `/tmp`, which is `tmpfs` here, so a cold cache after reboot still costs ~9.4 s regardless of bundling.
- The screen must be re-run whenever pi or a package changes graph, which is why it runs inside the hook rather than once by hand.
- A package that fails gate A is not permanently unbundleable: `--alias:#src=./src` would very likely make the two `#src/*` packages build, and the screen would then have to judge them like any other rather than refusing them on proof.

# Principles

What this setup optimizes for, stated once so no ADR has to re-derive it: fast, idempotent, declarative, bootstrapped, consistent.

Each section says what the word means here, what it bought, and which ADRs are examples.
The ADRs carry the reasoning; this file only points.
Two house rules:

- A fact that disagrees with an ADR is a defect in this file or grounds for a new ADR, not something to quietly patch here.
- Nothing here expires.
  A sentence that is only true of today's checkout is state, and that lives in `STATE.md`, not here.
  Same test as ADR-0026's tier question, pointed at time: would this sentence be false on another date?

## Fast

Measured in interactions, not seconds: one keystroke to any destination, and every question asked often answered without lifting the hands.
Modal tmux key tables entered by one chord [0012], which-key menus built from the config itself [0013], a sessionizer and scratchpad keyed off the session you are already in [0015], one judging agent rather than a slow advisor [0029].

This is also the test for lazy rendering: anything shown on demand -- a menu, a completion, generated help -- is fine as long as assembling it at press time costs less than keeping it up to date would.
A precomputed artifact is the wrong shape when its source changes more often than it is read.
Cost: every lazy-rendered surface has a builder, and generated state rots when the source is edited without a rerun.

## Idempotent

The bootstrap is safe to rerun any time, and rerun it does.
Each step checks before acting, and is silent when nothing changes [0005, 0056]; bugfix steps apply a patch only when the forward one matches, so a fix that has landed upstream makes the step a silent no-op rather than a spurious error [0057].

Idempotency also enabled a design choice: state that is checked on every run might as well be recomputed from its source every time, so caching is rarely worth it.
tmux re-derives its own location at relaunch [0010], tool routing is derived from the declaration [0046], the tmux palette is re-rendered from a tracked template on each theme switch [0052].

Cost: every consumer of this repo interacts with it through check-and-set, which `omarchy update` migrations break -- they write into tracked files and only check that some marker exists, not that the file is in a known shape [0049].
Tracked in the backlog.

## Declarative

Tools and state are named in files, and the complement tool runs from them: tools in `conf.d/*.toml` [0006, 0046], mise-managed binaries symlinked into XDG paths so normal lookup works with no shell trampoline [0007], environment variables as static files under `environment.d/` [0001], bootstrap steps gated on what the machine actually has rather than which distro it claims to be [0044].
Because the declarations are the source, testing one is cheap: run it against a throwaway server or scratch config and compare [0017, 0021].

Three boundary conditions:

- A keeps-it-correct check the distro runs out of its own state (RPM scriptlets, `dpkg --verify`) is not declarative: the source of truth has to be a file that exists in the repo, not `/var/lib`.
- Observed runtime is not the same as declaration -- reading a tool's live behaviour and codifying that bakes in a snapshot that rots on its next update [0045, 0051].
- When a task needs an imperative loop, the answer is to shell out to the imperative layer, not to bend the declarative tool until it barely does it (the footballing-vs-wrapper-script trade [0048]).

Cost: declarative tools want odd cases expressed in their model, and what they cannot see -- fine-grained runtime state diffing against its complement -- stays invisible.

## Bootstrapped

One command takes a fresh clone to a machine configured to spec; a machine's configuration should never live only in the machine's memory.
What carries this is not distro matching but capability checks -- same origin, different package systems [0044] -- and declarations that name their own spot, so "where is this configured" is always answerable: an agent's whole world imports from one CLI [0036], tools find whatever repo packages them [0046], and everything else gets a named note in the config layout [0048, 0053].
Where the bootstrapped environment itself took debugging to get right, that debugging lives in a doc (`environment-architecture.md`, `omarchy.md`) rather than in the session history of whoever did it.

Cost: this is a long bet that only pays once the machine it describes is old enough to need rebuilding, and until then the bootstrap has never exercised the paths the docs claim it does.
Corollary: cross-running the bootstrap against a machine you still have -- Mint against `omarchy` steps, or vice versa -- is the cheapest way to catch what has rotted since the last full run.

## Consistent

Hand-built tooling shares grammar across tools: the Hyprland Super chord mirrors tmux's Alt chord for the same actions [0055]; the herdr scratchpad nests a herdr session rather than tmux, so the popup keeps herdr's own keys [0077]; helix replaces nvim not because it is better at vim but because it is the only one that knows itself as the single implementation of the editor niche [0008].

Cost: coupled.
Changing the tmux tab grammar ripples into Hyprland, herdr, Helix and keyd; the same name being cheap to adopt once is not the same discipline as keeping four interconnected grammars aligned afterwards.

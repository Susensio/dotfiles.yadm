# ADR-0007: Link mise tools into XDG directories instead of PATH shims

Status: Accepted
Date: 2026-06-02

## Context

mise's default integration puts its shims on `PATH` and needs `mise activate` in every shell.
That means a shell hook on every startup and a layer of shim indirection between the shell and the real binary, for every invocation.

## Decision

Symlink mise-managed tools into standard XDG locations instead of using shims.
The `system-install` task ([ADR-0006](0006-manage-cli-tools-with-mise.md)'s `postinstall` hook) links binaries into `~/.local/bin`, man pages into `$XDG_DATA_HOME/man`, fish completions into `$XDG_DATA_HOME/fish/vendor_completions.d`, and node modules into `$XDG_LIB_HOME/node_modules`, using `ln --relative`.
Man pages and completions land where the normal lookup paths already find them — no shell hook required.

## Consequences

Shells start faster and stay ignorant of mise.
Costs: the symlink farm is a second source of truth that must be re-synced after every install or uninstall (`prune_broken_links` walks `TARGET_DIRS` for dangling links via `find -xtype l -lname "*/mise/*"`); the guard that stops this running from a local project (`check_execution_context`, gating on the hook env that mise 2026.8.9+ sets only for global-only operations) is still a heuristic, not a real sandbox; and because resolution no longer goes through mise for these globals, per-directory version switching does not apply to them.

## Measured cost

Measured in September 2026 against mise 2026.9.13 with 52 tools configured globally, the Context's "layer of shim indirection" turned out to be the smaller half of the cost.
A shim and `mise x -- fd` landed within about 10% of each other, and a direct symlink to the same binary was roughly 50x faster than either, so the shim was not a thin wrapper around an exec — it inherited `mise x`'s whole-toolset cost.
That cost grew roughly linearly with the number of configured tools: a one-tool config resolved in tens of milliseconds, and configs in the thirties-to-fifties of tools each cost a few hundred milliseconds more.
`MISE_TIMINGS=1` attributed the bulk of it to the missing-version enumeration and environment-construction steps, which each walk every configured tool, and `strace -f -c` on one invocation counted about 15,000 file-related syscalls where the healthy case reported upstream was nearer 2,200.
In the source, the shim dispatch path built a full toolset before it knew which tool owned the binary, and the exec path then resolved and install-checked over the whole toolset again.

The scaling was not a regression: it was present in the oldest release that could be run, and the shim path had been resolving the whole toolset since the first shim release (jdx/mise#213).
Upstream's three attempts at it (jdx/mise#11468, #11500, #11534) were all constant-factor on the same architecture — the last moved the maintainer's own benchmark from 56.8 ms to 52.3 ms on a small config — so no upgrade was going to remove the cost, and v2026.9.2 was about 100 ms slower than v2026.9.1 because jdx/mise#12771 added Rust component and target enumeration to work the shim path already did.

Three candidate causes were ruled out, recorded so they are not re-chased.
It was not the network: the docs say shims make one network attempt when the version cache is cold, which would have explained a one-second shim on its own, but `MISE_OFFLINE=1` changed nothing measurable.
It was not ecryptfs, despite `~` being a FUSE encrypted overlay and the shim's time being dominated by system time — it measured about 2x slower than ext4 for an equivalent directory scan, real but far too small to account for hundreds of milliseconds.
And it was not the machine: a direct symlink dispatched in 0 ms on the same box and the same pinned core, so the hardware was not the floor.

Two things follow for whoever reads this next.
The decision holds until upstream lands a resolution cache for the shim path keyed by config mtimes and cwd, or an opt-in binary-only shim mode that skips whole-toolset environment construction — either changes the cost model this rests on, and either is worth re-measuring against the numbers above before the farm is touched.
And the shim directory held 86 shims that nothing resolved to, because the shim farm was not on `PATH`; they were left in place as free and `mise reshim`-regenerated, which means a reader asking "are shims in use here" has to check `PATH` rather than the presence of that directory.


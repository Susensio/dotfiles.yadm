# ADR-0124: Price the whole Go catalog and print the index's own components beside the composite

Status: Accepted
Date: 2026-11-22

## Context

`pi-model-cost` priced only the Go models the config named, and printed one intelligence number per model: the published Intelligence Index composite.
Both hid evidence at the 2026-11-22 sync.
The catalog sells strong models no tier referenced — `muse-spark-1.3-contributor` at 37.0 with a 1.00% drain and the best intelligence-per-drain on the board, `hy4` at 35.0 — and they only appeared when the script was pointed at every model.
And `n/a` covered two different states at once: `kimi-k2.7-code` has four of the index's nine evaluations measured on its page, `longcat-2.5-free` has none.
The composite exists only when all nine are in, but the components are published per model regardless.

Reproducing the composite from the published weights is possible — the methodology page gives them, and the arithmetic reproduces the site's own number — but it only lands where the composite already exists, and filling the gaps by re-normalising over the components that are present drifts an estimate toward the mean of whatever happens to be measured: hiding components from models whose composite is known moves the answer by −6.0 to +6.8 index points, in whichever direction the missing evaluations happen to pull.

## Decision

`pi-model-cost` prices every Go model by default, because a model no tier names can still be the best answer the provider sells; `--configured` narrows it back to the alias and `enabledModels` rungs.

It prints Terminal-Bench 4.0 and Terminal-Bench-Science beside the composite, the two terminal-based evaluations the index weights at 10% and 15%, read from the record it already parses.
It does not reproduce the composite, re-normalise the weights over a subset, or estimate a missing component.

## Consequences

`n/a` now means "no comparable composite", not "no evidence": `kimi-k2.7-code` reads `n/a` with `1/-` beside it, which is a coding model failing the weighted coding evaluation rather than an unmeasured one.
A rung with no composite is placed on those components and on ADR-0103's harness key instead of on a number the script invented.

Accepted limitation: the components come from whichever of a model's records carries them, and a record without them prints `-/`; the score-disagreement guard is what keeps a neighbouring model's record out, so a page restructure shows up as missing components rather than as wrong ones.
Accepted limitation: Terminal-Bench 2.1 still appears in the payload and is not part of the index; reading it, as the `$comment` once did, compares models on a retired and much easier evaluation.
Accepted limitation: the four `cov`-style questions a reader may still have — how much is measured, and what a missing component would have contributed — are answered by the two columns and nothing else; an estimate needs its own record and a measured error before it ships.

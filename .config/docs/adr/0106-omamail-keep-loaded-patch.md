# ADR-0106: Declare Omamail's keepLoaded in the plugin clone from a bugfix step, instead of waiting for the release or wrapping omarchy plugin update

Status: Accepted
Date: 2026-11-06

## Context

Omamail ships as an Omarchy panel plugin: its manifest declares the `service`, `bar-widget` and `panel` kinds and no `keepLoaded`.
Omarchy's shell holds one `Loader` per panel plugin and activates it only while that panel is open, so closing the window destroyed the whole QML composition, and the next summon rebuilt it before the `FloatingWindow` inside it could exist.
Measured on 2026-11-06, a summon from the bar took 1303, 1404 and 1653 ms; with `keepLoaded` declared, the first window took 383 ms and later summons 96–158 ms, because only its visibility toggles.
The service and the Rust backend were not the cost: `omamail serve` had been up for 17 hours and the panel was rebuilt regardless.

Three routes were weighed.
Waiting for a release leaves a second of latency on the most used thing in the bar for as long as the maintainer's queue is long, and costs nothing to maintain.
Overriding `omarchy plugin update` to drop the edit, update and re-apply it would make updates transparent, at the price of a second artefact to write, keep in step with Omarchy's update command, and delete afterwards.
Editing the clone's manifest in place costs one documented hop per update and nothing else.

The fix belongs upstream, and the local edit belongs in the checkout yadm does not track.
`omarchy plugin validate` accepts the key and the running shell honours it once the plugin registry rescans.
Bug fixes for root-owned Omarchy files are already carried as bootstrap steps with a `.patch` asset ([ADR-0057](0057-omarchy-bugfix-patch-steps.md)); this is a user-owned clone edited in place, so it reuses the step lifecycle rather than the patch assets.

## Decision

`yadm/bootstrap.d/omarchy/bugfix/omamail-keep-loaded.sh` inserts `"keepLoaded": true` after the manifest's `id` line when the clone exists and the key is absent, then asks the running shell to rescan plugins.
The step is silent once the key is there, warns instead of guessing when the manifest no longer has the line to insert after, and is deleted once a release carries the key.

The clone is a git checkout that `omarchy-plugin-update` only fast-forwards, so the edit in place makes that update refuse to run.
The documented hop is `git -C ~/.config/omarchy/plugins/omamail checkout -- manifest.json`, the update, then the bootstrap that re-applies the step.

## Consequences

Omamail opens in about a tenth of a second after its first window instead of a second, at the price of the panel staying resident in the shell.
That residency measured about 40 MB of shell RSS and builds the panel once at shell start, opened or not.
A panel that lives for the whole session is a shape the plugin was not written for: its QML caches, message bodies and agent jobs used to be freed on every close, so growth across a long session is possible and was not verified beyond the summons above.

`omarchy plugin update omamail` fails until the manifest edit is discarded; that is an accepted limitation rather than something to work around twice.
Upstream shipping the key makes the step silently succeed, so it is deleted by hand, and a manifest that changes shape warns on every bootstrap until it is.

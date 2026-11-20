# Proposal: snapper timeline snapshots of `/home`

Status: drafted 2026-11-20 from the BACKLOG entry (marked **important** there), not built.
Linked from a one-line [BACKLOG](../BACKLOG.md) entry.

## Problem

Omarchy snapshots only `/` (config `root`), only before updates, and disables `snapper-timeline.timer`; nothing covers `/home`.
So the 2026-09-30 `yadm reset --hard` that wiped every uncommitted tracked change took hours of session forensics to undo (most recovered, `codex/config.toml` lost).

## Design

A `home` config (hourly, keep ~24 hourly / 7 daily / 4 weekly) as an idempotent bootstrap step plus a short ADR, one `pkexec`, and `btrfs-assistant` (Arch `extra`) as the GUI to browse and restore.

## Care points

- Omarchy's `install/config/snapper.sh` rewrites `SNAPPER_CONFIGS="root"` in `/etc/conf.d/snapper`, which silently drops a `home` timeline from the stock timers, so run `home` from its own systemd timer.
- `omarchy-snapshot create` loops over every config, so update snapshots will include `/home` too.
- Make `~/.cache` (and other churny dirs) separate subvolumes so snapshots stay small.
- Snapshots are not backups (same disk).

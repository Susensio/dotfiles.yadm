# ADR-0095: Run foot with its own terminfo instead of Omarchy's xterm-256color

Status: Accepted
Date: 2026-10-20

## Context

Omarchy ships `term=xterm-256color` in `foot.ini`, and in its alacritty config too; no upstream issue gives the reason.
Foot sets no environment variable that identifies it, because `TERM` is user-configurable; it answers the tertiary device attributes query instead, which a shell script cannot ask cheaply.
With `xterm-256color`, nothing told `bin/preview` it could use sixel, and `TERM_PROGRAM=foot` in an `[environment]` section was tried as a stand-in and judged a hand-made workaround.
Three alternatives were weighed: keep that variable, let tmux's own sixel detection decide and give up sixel outside tmux, or set `term=foot`, which foot's man page recommends.
Throwaway tmux servers showed what `term=foot` costs: tmux's `extkeys` feature, which `10_main.conf` granted only to `xterm*`, and the `ccolour`, `cstyle` and `clipboard` flags (the terminfo still carries their capabilities).
It gains `Smulx`, curly underlines, which `xterm-256color` lacks, and chafa picks sixel outside tmux by itself.

## Decision

`foot.ini` sets `term=foot`.
`10_main.conf` grants `foot*` the same terminal features it grants `xterm*`.
`bin/preview` uses sixel outside tmux by trusting chafa's own detection, and inside tmux when the client reports it.

## Consequences

A host without foot's terminfo entry fails with "unknown terminal" for `clear`, `less`, `vim` and `htop`: ssh targets, minimal containers, `sudo` into other machines.
Fix one host with `TERM=xterm-256color ssh host`; fix all by a wildcard `SetEnv TERM=xterm-256color` in `~/.ssh/config`, with `Host` blocks for hosts that do have the entry. Foot users report OpenSSH 8.7 or newer honours it; it was not verified here.
Copying `foot` and `foot-direct` to `~/.terminfo/f/` on the remote also works.
Check a host with `ssh host infocmp foot`.
nvim and vim do not know `foot` and can mishandle Ctrl combinations (modifyOtherKeys); nvim is the fallback editor here, so this is accepted.
Programs that enable features only for `TERM=xterm*` degrade silently; the tmux feature line was the one found, others are unknown.
If something terminal-related breaks only in foot, set `term=xterm-256color` and restart the windows before looking further; the `foot*` tmux line is then dead but harmless.
Windows opened before the change keep the old `TERM`.

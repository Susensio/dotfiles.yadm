# ADR-0069: Suspend-then-hibernate from every suspend entry point, with HibernateOnACPower=no instead of a plain suspend on AC

Status: Accepted
Date: 2026-09-29

## Context

The laptop sleeps in s2idle only, so a long sleep drained the battery.
The `suspend.sh` bootstrap step had made the lid run suspend-then-hibernate on battery and a plain suspend on AC, through logind's `HandleLidSwitch` and `HandleLidSwitchExternalPower`.
Omarchy's power menu Suspend ran a plain `systemctl suspend`, so the same intent behaved differently by entry point: a menu suspend never hibernated, and a lid closed on AC stayed in s2idle after being unplugged.
systemd offered no setting that turned `systemctl suspend` itself into suspend-then-hibernate; each caller had to ask for it.
systemd 261's `HibernateOnACPower=no` held the `HibernateDelaySec` countdown until AC was disconnected.

## Decision

Every suspend entry point we control asks for suspend-then-hibernate, and the AC-versus-battery distinction lives once in `sleep.conf.d` as `HibernateOnACPower=no`.
The lid uses suspend-then-hibernate on both power states, and the Omarchy menu extension overrides only the `system.suspend` entry's action.
A per-caller AC check (the lid's old `HandleLidSwitchExternalPower=suspend`) was discarded: it duplicated the policy per entry point and missed an unplug during sleep.

## Consequences

Unplugging a sleeping laptop now starts the hibernate countdown instead of leaving it in s2idle indefinitely.
A plain `systemctl suspend` typed by hand still only suspends; accepted, since no config reaches it short of wrapping `systemctl`.
The menu override masks any upstream change to what Suspend runs, while its label, icon, guard and position keep following upstream.

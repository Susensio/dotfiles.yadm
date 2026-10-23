# ADR-0098: Pass TRIM through LUKS with the persistent header flag and btrfs async discard, not the kernel cmdline or fstrim.timer

Status: Accepted
Date: 2026-10-23

## Context

The root filesystem is btrfs on a LUKS2 mapping opened by mkinitcpio's `encrypt` hook, and the SSD under it was never trimmed.
The mapping dropped discards (`lsblk --discard` showed 0B for `root`), because the kernel's `cryptdevice=` parameter carried no `:allow-discards`, and `fstrim.timer` was disabled anyway.

Three places could have allowed discards.
The `cryptdevice=` line lives in `omarchy-defaults.conf`, owned by the `omarchy-settings` package, so editing it would be undone by an update; repeating the parameter in a drop-in of our own would depend on which of two `cryptdevice=` values the hook reads.
`rd.luks.options=discard` belongs to the systemd `sd-encrypt` hook, which this initramfs does not use.
LUKS2 stores activation flags in its header: `cryptsetup refresh --allow-discards --persistent` writes one that every later open honours, whatever the command line says.

For the trimming itself, btrfs has enabled `discard=async` by default since Linux 6.2 on any device that supports discards, so once the mapping passes them through, the filesystem trims freed extents as it goes; `fstrim.timer` would only repeat that work weekly.

## Decision

Set the persistent `allow-discards` flag in the LUKS2 header, and rely on btrfs's default async discard instead of enabling `fstrim.timer`.
Setting the flag needs the passphrase, because the `encrypt` hook does not leave the volume key in the kernel keyring, so the bootstrap cannot apply it unattended: its `luks-discards.sh` step warns with the command when the root mapping drops discards on a disk that supports them, and is silent otherwise.

## Consequences

The setting lives in the disk, not in tracked files: a reinstall or a new LUKS header loses it, and the bootstrap's warning is what brings it back.
With discards passed through, an attacker holding the disk can see which blocks are free, and so roughly how full the filesystem is and its layout; contents stay encrypted. This was accepted as the usual trade for SSD longevity and sustained write speed.
Async discard depends on the mount seeing a discard-capable device: `findmnt -no OPTIONS /` should list `discard=async` after the first boot with the flag; if a kernel stops defaulting to it, `fstrim.timer` is the fallback.

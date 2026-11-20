# Proposal: TPM2 auto-unlock of the LUKS root with a PIN, and a long passphrase behind it

Status: drafted 2026-11-20, not built; every step below that touches a secret is done by the owner by hand, outside any AI session.
It takes up [BACKLOG's](../BACKLOG.md) deferred TPM2 item, which ruled out a PIN; the ADR is written at acceptance, when the plan is deleted and the backlog entry replaced by the record, per the repo's records rule.
The initramfs switch in stage 1 is the risk the owner flagged: no stage 2 step runs before the passphrase-only reboot has proven the new initramfs, and the kept old UKI stays a boot option until the PIN boot has proven itself.

## What is wrong

A cold boot and a hibernate resume both ask for the LUKS passphrase at the Plymouth prompt, so the machine's only knowledge factor sits at its most exposed interface.
A passphrase meant for typing at a boot prompt is kept short enough to type; the passphrase slot deserves a long one nobody types except in fallback, and the everyday unlock should be a short PIN the TPM verifies.

## Facts this machine holds (checked 2026-11-20)

- LUKS2 on `/dev/nvme0n1p2` (UUID `8a5ab037-27e8-4471-8068-a46984e59ae4`), single passphrase keyslot 0, no tokens.
- TPM2 present, PCR 7 and 11 populated; Secure Boot off with `SetupMode` 0; the UKI is measured by systemd-stub (PCR 11).
- The root is unlocked in the initramfs by mkinitcpio's busybox `encrypt` hook through `cryptdevice=` on `/etc/kernel/cmdline`, which the sd-encrypt hook cannot parse.
- The busybox `encrypt` hook ignores TPM2 keyslots entirely, so today the TPM can unlock nothing: the switch to systemd's `sd-encrypt` hook is the prerequisite for the whole project, not an optional hardening step.
- Omarchy forces the busybox hook line for every non-Apple-Silicon machine in the package file `/etc/mkinitcpio.conf.d/00-omarchy-hooks.conf`, so the local override must sort after it (a `90-` name) and survive as an untracked `/etc` drop-in that `omarchy update` leaves alone.
- The busybox line carries `btrfs-overlayfs`, a busybox runscript with no systemd-line equivalent; it is what lets the Limine Snapshots entry boot a read-only snapshot (writable through an overlay).
- The hibernate-resume unlock is the same initramfs asking the same prompt, so it is covered by the same change.
- ADR-0098's persistent `allow-discards` header flag is untouched by all of this; `discard` in the crypttab options is what passes discards through under the new hook.

## Design

- The initramfs switches to systemd's `sd-encrypt` hook via a local `90-` drop-in under `/etc/mkinitcpio.conf.d/`, rewriting the HOOKS line the omarchy-settings drop-in sets.
- The unlock config moves from the kernel cmdline (`cryptdevice=`) to `/etc/crypttab` with `x-initrd.attach`, sd-encrypt's non-deprecated path; `root=` switches to the partition UUID and `cryptdevice=` goes.
- Stage 1 proves the new initramfs with the passphrase prompt alone, before anything touches the passphrase or the TPM.
- Then the long passphrase replaces the current one, and a TPM2 keyslot bound to PCR 7+11 with a PIN is enrolled, leaving the passphrase slot as the fallback.

## Stage 0: record and backup (owner, by hand)

The header backup is the one artifact that can lose data misused (a TPM slot must never be the only keyslot, and the header image plus the disk enables offline brute-force of the passphrase, so it is a secret of the vault passphrase's rank: offline home, never on a machine).

```
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header-$(hostname).img
sudo cryptsetup luksDump /dev/nvme0n1p2 > luks-dump-$(hostname).txt
```

Both stored offline beside the recovery codes and the vault passphrase (`docs/secrets.md`).
Choose the new long passphrase now and write its paper copy beside them, since it replaces the short one as the ultimate fallback.
Check `yadm status` clean first.

## Stage 1: the initramfs switch (agent-executable, pkexec per file)

Every file is untracked `/etc` state written through pkexec; the old UKI is kept as the fallback boot entry.

`/etc/mkinitcpio.conf.d/90-luks-tpm2-hooks.conf` (root, 0644):

```bash
# 00-omarchy-hooks.conf sets the busybox line for every non-Apple-Silicon
# machine; the TPM2 unlock (docs/plans/tpm2-luks.md) needs sd-encrypt instead,
# so this drop-in sorts after it and rewrites the line.  Reconsider this line
# whenever the package file changes its own.
# btrfs-overlayfs is a busybox runscript with no systemd equivalent: the
# Limine Snapshots entry's writable-boot dies with this line, accepted in the
# ADR this plan becomes.
HOOKS=(base systemd plymouth sd-vconsole keyboard kms block sd-encrypt filesystems fsck)
```

`/etc/crypttab` (root, 0644), active line:

```text
# x-initrd.attach unlocks in the initramfs, replacing cryptdevice= on the
# cmdline (docs/plans/tpm2-luks.md); discard passes ADR-0098's discards through.
root PARTUUID=5776a77d-92c9-4e66-b7ac-9fa96f64332e - tpm2-device=auto,discard,x-initrd.attach
```

`/etc/kernel/cmdline` becomes (cryptdevice and root=mapper gone):

```text
root=PARTUUID=5776a77d-92c9-4e66-b7ac-9fa96f64332e rootflags=subvol=@ rw rootfstype=btrfs zswap.enabled=0 resume=/dev/mapper/root resume_offset=1941231
```

Note `tpm2-device=auto` before any enrollment does nothing harmful: crypttab options are inert for a volume with no TPM token yet, so both stages can share one crypttab line.

Then, via pkexec: copy the current UKI to `/boot/EFI/Linux/` as a fallback entry file, run `mkinitcpio -p linux-omarchy`, and let `limine-entry-tool` rebuild the UKI and the Limine entries.
`omarchy refresh limine` reverts untracked `/boot/limine.conf` edits (the existing `timeout: 1` backlog note): the fallback entry needs re-adding after each refresh until the plan completes.
Verify the built image: `lsinitcpio` on the new UKI's initramfs shows `/etc/crypttab` and the tpm2 binaries, and `limine-entry-tool --get-cmdline` shows no `cryptdevice=`.

**Test reboot** (owner): reboot; expect the Plymouth passphrase prompt as before; type the current passphrase; boot lands; `findmnt -no OPTIONS /` still lists `discard=async`.
Then try the Limine Snapshots entry: without `btrfs-overlayfs` it either fails to boot the RO subvol or boots it without an overlay (writes fail); whichever it does, that is the accepted limitation the ADR records, and if the owner instead decides snapshot boot must survive, the kept old UKI is the snapshot entry's boot path and stays in the menu permanently.

## Stage 2: secrets (owner, by hand, only after the test reboot passed)

1. The long passphrase first, while the current short one still opens the disk:

       sudo cryptsetup luksChangeKey /dev/nvme0n1p2

   Slot 0 is replaced in place (old passphrase in, long one twice).
   Confirm: `luksDump` still shows one keyslot, and a reboot asks for the long passphrase.
   File the paper copy with the others.

2. Then the TPM2 slot with PIN:

       sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+11 --tpm2-with-pin=yes /dev/nvme0n1p2

   Asks for the long passphrase (to authorize), then a new PIN twice.
   Six digits or more: the PIN is typed at every boot prompt, so guessing-cheap shapes (4 digits) are out; it defends a disk, not a phone screen.
   Confirm: `luksDump` shows the passphrase keyslot plus a tpm2 keyslot, and `Tokens:` gains `systemd-tpm2` with PCR 7,11.

3. Prove it: cold boot asks for the PIN at Plymouth; `cryptsetup luksDump` on a later whim still shows both slots.
   Also resume: lid → suspend-then-hibernate → resume, expecting the PIN prompt (the resume path is the same initramfs).

## What the PIN changes in the threat model (the ADR's content)
- PCR 11 measures the UKI, so every kernel update rebuilds it and breaks the seal; the next boot asks for the long passphrase once, and a re-enroll restores the PIN path (`systemd-cryptenroll` again, same command).  Accepted: one long-passphrase boot per kernel update is no worse than today's every-boot passphrase.
- The seal without Secure Boot proves only "this boot chain ran": the ESP is unencrypted and public, so an attacker who can also guess or observe the PIN unlocks the disk.  The PIN raises that bar from zero (TPM-only, the shape the backlog first sketched) to a knowledge factor; the other half is Secure Boot via sbctl, deliberately out of scope (the backlog's own analysis).
- A firmware update, a TPM clear, or a `SetupMode` change falls back to the long passphrase prompt; nothing is lost, and the PIN is re-enrolled after re-sealing.
- Shoulder-surfing and smudge attacks now watch a 6-digit PIN instead of a passphrase; the lock screen still guards the running system, so the PIN defends the boot path only.
- Hibernation is not TPM-gated here: resume asks the PIN the same way a cold boot does, since both ask at the same initramfs prompt.
- The deliberate contrast with `nuc`'s rebuild (the homelab's `docs/plans/rebuild.md`): there, Secure Boot is on and the enrollment takes no PIN, because the point is the unattended reboot — a server no one types at — while `dell`'s PIN is exactly what makes up for Secure Boot being off here.

## Rollback

- Before stage 2: boot the kept old UKI (menu entry), which asks the current passphrase and unlocks exactly as today; restore the three `/etc` files and rebuild, or leave them, since nothing about them breaks the old UKI's own path.
- After stage 2 step 1: the long passphrase is now the only unlock; a forgotten long passphrase at this point is the header backup's purpose — `cryptsetup luksHeaderRestore` from the offline image returns the disk to stage 0's slots (short passphrase, no TPM slot).
- After stage 2 step 2: the passphrase slot still exists; `systemd-cryptenroll --wipe-slot=tpm2` removes the TPM slot if it misbehaves, and the header restore is the nuclear option (it also removes the TPM slot and reverts the passphrase to the short one, which should then be changed again).
- The fallback UKI entry stays in the Limine menu until the PIN boot has proven itself; after that, remove it and the entry's re-add note.

## After completion
- The ADR records the taken-up decision (PIN supersedes the backlog's "PIN ruled out"), the busybox→sd-encrypt switch, and the accepted limitations (kernel-update re-enrolls, Snapshots-entry writable boot dead, Secure Boot out of scope); the plan is deleted at acceptance and the backlog entry goes with it.
- A silent idempotent bootstrap step like `luks-discards.sh` warns when the sd-encrypt drop-in, the crypttab line, or the keyslot count drifts (a reinstalled system or a header restore leaves no TPM slot and nothing warns today).
- `docs/secrets.md` gains a line: the LUKS passphrase's paper copy and the header image live in the offline set.

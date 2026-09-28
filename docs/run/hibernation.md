# ZFS hibernation investigation and acceptance

Status: the resume-first boot path passes in the disposable VM. The upstream ZFS
consistency risk was explicitly accepted on 2026-09-29 and production hibernation
is enabled. Physical acceptance is still required. This runbook does not claim
that the current upstream stack provides safe ZFS hibernation.

## Known constraints

The pinned NixOS ZFS module at
`5d6035951d69ff26910e558f04960d8556981a2a` exposes
`boot.zfs.unsafeAllowHibernation`, defaulting to false. It explicitly describes
hibernation as unsafe and potentially causing corruption. It also rejects
hibernation combined with forced pool import.

There are two ZFS concerns:

1. Importing or resetting a pool before resuming changes storage underneath the
   saved kernel state. Ordering can prevent this failure mode.
2. ZFS write/transaction behaviour during hibernation itself has unresolved
   consistency concerns. Correct initrd ordering does not establish that these
   are fixed. See the [NixOS investigation](https://github.com/NixOS/nixpkgs/pull/208037).

Separately, upstream Linux's `hibernation_available()` checks
`security_locked_down(LOCKDOWN_HIBERNATION)`. Encrypted swap alone does not bypass
that restriction. Verify the actual selected kernel and its patches rather than
assuming Secure Boot plus LUKS implies supported authenticated resume.

## Candidate resume layout

Use a persistent swap LV inside the outer LUKS container and outside ZFS. Choose
its size using the destination's RAM, expected swap use and image requirements;
the current 64 GiB swap LV is only a starting reference, not a validated size.

Do not use a ZFS swapfile, a swap zvol, or random-key-per-boot swap for the resume
image. The resume device must be addressable in initrd after LUKS/LVM activation
without importing any ZFS pool or mounting the root dataset.

## Required boot ordering

```text
signed boot image
  → initrd drivers/network
  → LUKS unlock (TPM+PIN or either recovery credential)
  → LVM activation
  → attempt resume from the persistent swap LV
      → success: return to the saved kernel/session; no root reset
      → no image: import ZFS, reset root, mount datasets, cold boot
      → invalid/unusable image: explicit failure handling before modifying pool
```

The host uses a systemd initrd. Implement and inspect actual unit dependencies;
adding a legacy `postResumeCommands` snippet does not establish ordering for this
host. Ensure every pool import and root-reset path is downstream of the resume
attempt. Disable forced imports for normal boot.

Record the policy for failed resume. Once a cold boot or recovery environment
has modified datasets, a previously saved image must not subsequently be resumed.
An explicit cold-boot recovery procedure must invalidate/discard the old image
before permitting storage mutation. Do not present a transient resume failure
as equivalent to safely having no image.

## Secure Boot / lockdown investigation

On the actual selected kernel, inspect:

```console
cat /sys/power/state
cat /sys/power/disk
cat /sys/kernel/security/lockdown
swapon --show
journalctl -b -k
```

Record kernel, ZFS and systemd versions; Secure Boot state; resume-device identity;
and any lockdown denial. Absence of a sysfs path is itself a result to investigate.

If authenticated hibernation requires an out-of-tree patch set, document its
source, supported kernel, signing/encryption model and maintenance burden before
adopting it. Disabling lockdown or removing the hibernation check is a security
tradeoff, not authenticated hibernation. Do not silently change that policy to
make a test pass. Keeping firmware signature checks while weakening runtime
lockdown still changes the protection provided by the boot chain.

## Test sequence

First use disposable VM data and test identities:

1. Verify normal cold boot and all three unlock routes.
2. Start processes with observable in-memory state. Write an unlisted sentinel
   on ephemeral root and persistent sentinels with recorded hashes.
3. Hibernate to disk, boot again through UEFI, and unlock.
4. Confirm the same processes/session return and the ephemeral sentinel remains.
5. Confirm no pool import/root rollback occurred before successful resume.
6. Verify persistent hashes, pool status and a completed scrub.
7. Reboot normally; confirm only the ephemeral sentinel disappears.
8. Repeat under write load, memory pressure and after an OS generation change.
9. Exercise missing/invalid resume images, a changed TPM policy and recovery
   unlocking without permitting a stale image to resume against changed storage.

Repeat the successful flow on the destination laptop, including its critical
battery action and suspend-then-hibernate behaviour. Resume from the appropriate
installed generation; a new kernel booted after an update may not accept an image
created by the old kernel.

Until this acceptance sequence passes, UPower uses `PowerOff` at the critical
battery threshold rather than attempting an unvalidated hibernation.

## Acceptance record

On 2026-09-29, the final bounded VM test completed in 241.53 seconds. It installed
the NixOS system into a self-contained target store and activated the standalone
Home Manager generation, then booted the installed disk through persistent UEFI
variables and a persistent software TPM, unlocked the LUKS2 container with
TPM2+PIN, and restored an image from the LVM swap LV before importing
`w0rkhorse`. The original boot ID and sentinel process ID were preserved, a
RAM-backed sentinel survived, and `zpool status -x w0rkhorse` reported no known
data errors after resume.

The run used `boot.zfs.unsafeAllowHibernation = true`. The same production opt-in
was enabled after the risk was explicitly accepted. Recovery credentials and TPM
replacement were omitted from this bounded run because those unlock paths had
already passed dedicated VM cycles; resume after recovery unlock remains a
separate acceptance case.

Still document during physical acceptance:

- Whether hibernation is permitted by kernel lockdown.
- Whether boot ordering is correct and resume works in the VM and on hardware.
- Which upstream ZFS consistency limitations remain.
- Any explicit experimental opt-in and security-policy changes.

Passing repeated tests is evidence of those runs, not a resolution of known
upstream consistency limitations. Production hibernation is enabled following
explicit risk acceptance, but physical acceptance remains outstanding.

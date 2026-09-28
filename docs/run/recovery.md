# Unlocking and recovery

Prerequisites: complete [machine preparation](prepare-new-machine.md) and
[recipient TPM enrolment](receive-new-machine.md#enrol-the-tpm) before using
the normal TPM-backed boot path.

## Normal local boot

Enter the user PIN/password at the initrd prompt. The TPM slot must require both
that input and the configured TPM policy. The system then attempts hibernation
resume before importing ZFS or resetting root. On a cold boot it imports the pool,
resets only root, mounts persistent datasets and provisions runtime SOPS secrets.

SSH authentication, the disk PIN and the normal login password are different
credentials. None should silently substitute for the others.

## Remote boot unlocking

The planned initrd SSH port is 2222, with public-key authentication and a separate
host identity. Use a verified known-hosts entry for `[HOST]:2222`.

```console
ssh -p 2222 root@HOST
```

Inside the initrd, use the systemd password agent, which the implementation must
include:

```console
systemd-tty-ask-password-agent --query
```

Answer the pending TPM PIN or recovery-passphrase request. The initrd must offer
a usable passphrase fallback when TPM policy evaluation fails; test this rather
than assuming a graphical PIN prompt handles it correctly. Exit once unlocking
completes; normal SSH uses port 22 and its own host fingerprint.

The first implementation should use a supported wired NIC with DHCP. A Wi-Fi,
VPN or dock dependency needs explicit initrd support. Do not assume the desktop's
NetworkManager profiles or SOPS secrets are available before disk unlocking.

The initrd host private key is in early boot material on the unencrypted ESP.
Its purpose is distinct from the normal SSH/SOPS host key. A copied boot disk can
expose it; it is not a hardware-backed attestation of the laptop.

## PCR change or failed TPM

Use the user recovery key to unlock without the TPM. Investigate whether the
change was an expected firmware/boot update, Secure Boot policy change, TPM
reset or hardware replacement. Re-enrol only from the intended trusted boot.

The user recovery slot is added on the first installed boot, after the initial
IT-passphrase unlock and before TPM enrolment. It is independent of the TPM slot.

Add and test the replacement TPM slot before deleting the old TPM slot. Identify
slots with `cryptsetup luksDump`; do not use a broad wipe operation that might
remove recovery slots. Update the header backup after successful rotation.

Do not repeatedly guess a TPM PIN: failed attempts can engage TPM dictionary
attack lockout. The independent recovery slot remains the recovery route.

## IT recovery on another machine

Use a trusted Linux rescue environment with cryptsetup, LVM and a compatible
OpenZFS version. Identify the LUKS partition by serial and UUID; do not use the
example path verbatim.

For data extraction, keep the source read-only. Example using the proposed names:

```console
sudo cryptsetup open --readonly /dev/disk/by-uuid/LUKS-UUID recovery-crypt
sudo vgchange -ay w0rkhorse
sudo zpool import -d /dev/w0rkhorse
```

The first command prompts for the IT passphrase, independent of the original
TPM. The last command lists importable pools; select the recorded pool GUID.
With `/mnt/recovery` created as an empty recovery mount root:

```console
sudo zpool import -N -o readonly=on -o cachefile=none \
  -R /mnt/recovery -d /dev/w0rkhorse POOL-GUID
```

For the proposed legacy-mounted home dataset, create its recovery mountpoint
and mount it explicitly:

```console
sudo mkdir -p /mnt/recovery/home
sudo mount -t zfs -o ro w0rkhorse/home /mnt/recovery/home
```

Mount other datasets as needed and extract files. Do not execute the root-reset
hook. Do not upgrade pool features during recovery. If ZFS reports the pool as
active on another host, first establish that the original machine is powered off
and the pool is not in use. A forced import is an explicit recovery action, not
the default. Never later resume a saved hibernation image after modifying its
pool from another boot; see [hibernation recovery](hibernation.md).

Unmount the recovered filesystems, export the pool, deactivate only its VG and
close `recovery-crypt` before disconnecting the disk.

If the header is damaged, preserve a disk image before attempting header repair.
Use only the matching escrowed header and documented recovery credentials.
Restoring an old header can also restore old credentials. A passphrase cannot
repair missing ciphertext or an irrecoverably damaged disk.

## Credential rotation

For either recovery credential:

1. Add the replacement with `cryptsetup luksAddKey`.
2. Test its specific slot using `cryptsetup open --test-passphrase --key-slot`.
3. Update the appropriate IT/user escrow record.
4. Remove only the superseded slot using `cryptsetup luksKillSlot`.
5. Refresh the header backup and retire superseded recovery material.

Keep the normal TPM slot and the other recovery slot working throughout. Changing
an unlock credential does not re-encrypt all data with a new volume key; suspected
volume-key compromise requires a separate re-encryption/reprovisioning plan.

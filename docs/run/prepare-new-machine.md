# Preparing a new machine

## Goal

A system formatted as follows:

```text
GPT disk
├── ESP: 1 GiB FAT32, mounted at /boot
└── LUKS2: cryptroot
    └── LVM: w0rkhorse
        ├── swap: persistent swap LV, sized for hibernation
        └── zfs: remaining space, ZFS pool w0rkhorse
            ├── root     → /          reset on cold boot only
            ├── nix      → /nix       persistent
            ├── home     → /home      persistent
            └── persist  → /persist   persistent system state
```

We configure the system with an impermanent root with explicit exceptions.

Based on the [disk configuration for luke-w0rkhorse](../../system/luke-w0rkhorse/disk-config.nix).

The host must already exist in the flake — hardware profile, host directory,
SOPS identity and both flake entries. See
[Enrolling a new host in the tree](enrol-new-host.md) if it doesn't.

After preparation and [recipient enrolment](receive-new-machine.md#enrol-the-tpm),
the LUKS container contains three keys:

| Slot | Key name | Use case |
| --- | --- | --- |
| 0 | IT recovery | IT department decrypting the disk without access to the TPM, user pin, or user recovery passphrase |
| 1 | User recovery | User decrypting the disk without access to the TPM, user pin, or IT recovery passphrase |
| 2 | User TPM pin | User decrypting the disk with a TPM-assisted short pin |
 
## References

- [Impermanence](https://github.com/nix-community/impermanence)
- [nixos-anywhere reference](https://github.com/nix-community/nixos-anywhere/blob/main/docs/reference.md)
- [nixos-anywhere secret staging](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/secrets.md)
- [sops-nix bootstrap and impermanence](https://github.com/Mic92/sops-nix)
- [LUKS2 TPM/PIN enrolment](https://man7.org/linux/man-pages/man1/systemd-cryptenroll.1.html)
- [Pinned NixOS ZFS module](https://github.com/NixOS/nixpkgs/blob/5d6035951d69ff26910e558f04960d8556981a2a/nixos/modules/tasks/filesystems/zfs.nix)

## Write USB key

1. Download the [NixOS minimal ISO](https://nixos.org/download/).
2. Identify the USB device with `lsblk`.
3. Write the image to the whole device:

```shell
sudo dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Prepare the firmware

1. Enable and clear the TPM.
2. Enable Secure Boot in Setup Mode.

## Boot into the NixOS installer

```shell
sudo passwd

nmtui
ip addr

sudo systemctl start sshd
```

## Install from another machine

At the installer's local console, obtain its SSH host public key:

```shell
ssh -o UserKnownHostsFile=installer-known-hosts root@192.168.9.18
```

Check the target disk using the same verified host identity:

```shell
ssh -o UserKnownHostsFile="$PWD/installer-known-hosts" \
  -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes \
  root@192.168.9.18 lsblk
```

Ensure the target matches what is in the system's disk configuration.

Create a dedicated installer client key on the provisioning machine. Keep it
outside the repository so a failed install can be resumed with the same key:

```fish
set --global --export host luke-w0rkhorse
ssh-keygen -t ed25519 -N '' -f ~/.ssh/"$host"-installer
```

Install using the IT recovery passphrase as the initial LUKS key:

```fish
just host-install "$host" 192.168.9.18 /dev/nvme0n1 ./installer-known-hosts ~/.ssh/"$host"-installer
```

Disko prompts for the IT recovery passphrase during formatting of the disk. The
recipe first prompts once for the installer root password and passes it to SSH
and nixos-anywhere. It kexecs into an installer with ZFS support, verifies that
ZFS can be loaded, refreshes the host's facter report, streams the existing host
identity to the mounted target, generates a fresh Secure Boot bundle with the
nixpkgs revision pinned by `flake.lock`, uses it to sign the installed boot
assets, enrols it with Microsoft trust, and completes installation. This assumes
the firmware is already in Setup Mode as described above; enrolment fails rather
than forcing past an incompatible firmware state.

The recipe reads `sops.defaultSopsFile` from the host's own NixOS
configuration, so the identity is always streamed from the secrets file the
host is wired to use.

If installation fails after Disko and identity provisioning are complete, resume
against the running kexec installer using the same host pin and client key:

```fish
just host-install-resume "$host" 192.168.9.18 ./installer-known-hosts ~/.ssh/"$host"-installer
```

The kexec installer retains the authorized client key, not the original root
password. The recipes leave the client key in place on both success and failure;
remove the dedicated private/public key pair once installation is complete and
you no longer need to resume it.

After the installed system boots, verify Secure Boot before continuing with the
recovery-slot and TPM enrolment steps.

## First boot

Unlock the system using the IT passphrase.

### Record recovery credentials

The two recovery passphrases must be different. The IT passphrase is the value
entered at Disko's installation prompt; the user recovery passphrase is
established below. The recipient chooses the TPM PIN and enrols the TPM using
the [recipient runbook](receive-new-machine.md#enrol-the-tpm).

```fish
read --silent --global --export --prompt-str 'IT recovery passphrase: ' IT_RECOVERY_PASSPHRASE
echo
read --silent --global --export --prompt-str 'User recovery passphrase: ' USER_RECOVERY_PASSPHRASE
echo
set LUKS_PARTITION /dev/disk/by-partlabel/disk-disk1-root
```

### Backup LUKS metadata

Take a backup of the LUKS metadata:

```fish
cryptsetup luksHeaderBackup "$LUKS_PARTITION" \
  --header-backup-file (hostname)-luks-header.img
```

Escrow this file to off-device storage for recovery in case writing the updated keys fails.

### Enroll user recovery disk encryption key

Add the independent user recovery passphrase:

```fish
sudo cryptsetup luksDump "$LUKS_PARTITION"

sudo cryptsetup luksAddKey \
  --key-file (printf %s "$IT_RECOVERY_PASSPHRASE" | psub --fifo) \
  "$LUKS_PARTITION" \
  (printf %s "$USER_RECOVERY_PASSPHRASE" | psub --fifo)

sudo cryptsetup luksDump "$LUKS_PARTITION"
```

Test each recorded slot directly:

```fish
sudo cryptsetup open --test-passphrase --key-slot 0 \
  --key-file (printf %s "$IT_RECOVERY_PASSPHRASE" | psub --fifo) \
  "$LUKS_PARTITION"
sudo cryptsetup open --test-passphrase --key-slot 1 \
  --key-file (printf %s "$USER_RECOVERY_PASSPHRASE" | psub --fifo) \
  "$LUKS_PARTITION"
```

## Secure Boot

Confirm the machine booted the installed image and verify the resulting state:

```console
❯ sudo sbctl status
Installed:      ✓ sbctl is installed
Owner GUID:     e4d8ef5f-e7db-4afe-aeaa-8ba4825220ea
Setup Mode:     ✓ Disabled
Secure Boot:    ✓ Enabled
Vendor Keys:    microsoft

❯ sudo sbctl list-enrolled-keys
PK:
  Platform Key
KEK:
  Key Exchange Key
  Microsoft Corporation Third Party Marketplace Root
  Microsoft RSA Devices Root CA 2021
DB:
  Database Key
  Microsoft Corporation Third Party Marketplace Root
  Microsoft Root Certificate Authority 2010
  Microsoft RSA Devices Root CA 2021
  Microsoft RSA Devices Root CA 2021
  Microsoft Root Certificate Authority 2010

❯ sudo sbctl verify
Verifying file database and EFI images in /boot...
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-1-tfkojy6bt2jei73i2mbhkyjsb6afy65kbfn66ttmr4264hgvm55a.efi is signed
✗ /boot/EFI/nixos/kernel-6.18.53-aw35763v42nge2tecosc42ft252qh7x4ajqojggxnuexnfzy3xaq.efi is not signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
sudo sbctl list-enrolled-keys
```

Escrow the private bundle from `/var/lib/sbctl` to secure off-device storage.
Retain its public exports and a recovery plan for the firmware trust database.

Once complete, put Secure Boot into Deployed Mode.

## Hand off to the recipient

Supply the tested user recovery passphrase through the agreed secure channel.
The recipient follows [Configuring a newly received machine](receive-new-machine.md)
to choose their TPM PIN and enrol the third key. Until that enrolment is complete,
only the IT and user recovery keys are present.

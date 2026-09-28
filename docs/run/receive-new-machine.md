# Configuring a newly received machine

## Goal

You've just received a new Linux system and want to get onboarded.

## First boot

Unlock the system with your supplied user recovery passphrase.

### Record credentials and PCR configuration

Use the user recovery passphrase supplied during preparation and choose your
TPM PIN below. The TPM PIN is separate from both recovery passphrases.

```fish
read --silent --global --export --prompt-str 'User recovery passphrase: ' USER_RECOVERY_PASSPHRASE
echo
read --silent --global --export --prompt-str 'TPM PIN: ' TPM_PIN
echo
set --global --export TPM2_PCRS 4+7+9+12
set LUKS_PARTITION /dev/disk/by-partlabel/disk-disk1-root
```

## Enrol the TPM

Use the tested PCR set supplied through `TPM2_PCRS`. Authenticate the enrolment
with the user recovery passphrase and set the TPM PIN from the environment:

```fish
PASSWORD="$USER_RECOVERY_PASSPHRASE" NEWPIN="$TPM_PIN" \
  sudo --preserve-env=PASSWORD,NEWPIN systemd-cryptenroll "$LUKS_PARTITION" \
  --tpm2-device=auto --tpm2-with-pin=yes \
  --tpm2-pcrs="$TPM2_PCRS"
```

## Set your system password

```fish
passwd
```

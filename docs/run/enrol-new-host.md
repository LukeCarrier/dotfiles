# Enrolling a new host in the tree

## Goal

A new NixOS host wired into the flake: hardware profile, host directory, SOPS
identity, secrets file, and flake entries. This is everything short of
[preparing and installing the machine](prepare-new-machine.md).

Everything below assumes a fish shell. In the YAML snippets, `$host` stands
for the literal hostname:

```fish
set --global --export host luke-c0nstruct
set --global --export user lukecarrier
```

## Generate the host identity

Create the host's SSH keypair outside the repository. It is encrypted into
SOPS below and the plaintext copy is shredded afterwards, but keeping it out
of the tree means a failed enrolment never leaves a private key in a working
copy:

```fish
ssh-keygen -t ed25519 -N '' -C "$host" -f ~/.ssh/"$host"-host
```

This single keypair is both the machine's OpenSSH host identity and its SOPS
age identity, exactly as for the existing hosts.

Derive the age recipient from the public key:

```console
ssh-to-age < ~/.ssh/"$host"-host.pub
```

## Register the recipient in `.sops.yaml`

Add the recipient to `keys`:

```yaml
keys:
  - &$host age1...
```

Add a recipients group for the host's secrets file, and a creation rule so
`secrets/<file>.yaml` is encrypted to it:

```yaml
recipients:
  - &<secrets-file>
    - *me
    - *$host
creation_rules:
  - path_regex: ^secrets/<file>\.yaml$
    age: *<secrets-file>
```

`*me` keeps the recipient that lives in `.sops/keys`, which the install recipe
stages into the user's `~/.config/sops/age/keys.txt` for Home Manager.

## Create the secrets file

The file is encrypted in place against the rule above:

```console
$EDITOR secrets/<file>.yaml
sops -e -i secrets/<file>.yaml
```

It needs, at minimum:

```yaml
nix:
  github: <token>
ssh:
  host:
    private: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      ...
    public: ssh-ed25519 AAAA... $host
```

- `ssh.host.{private,public}` is the generated host keypair. The install
  recipe streams it to the target as the OpenSSH host key, and sops-nix uses
  it on the running system as the age identity for system-level secrets.
- `nix.github` is consumed by [platform/nixos/common.nix](../../platform/nixos/common.nix)
  to render GitHub access tokens for nix-daemon. Add anything else the host's
  platform or employer modules expect.

Multiline scalars are easy to mangle; verify the private key round-trips
before shredding anything:

```fish
sops --decrypt --extract '["ssh"]["host"]["private"]' secrets/<file>.yaml > /tmp/ck
chmod 600 /tmp/ck
ssh-keygen -y -P '' -f /tmp/ck
shred -u /tmp/ck
```

The derived public key must match `ssh.host.public`. Recipients added to an
existing file need `sops updatekeys secrets/<file>.yaml`.

## Generate the hardware report

Generate `facter.json` on the target machine itself — from a live environment
before install, or from the installed system afterwards. Never from the
disposable test VM:

```console
nix run --extra-experimental-features 'flakes nix-command' nixpkgs#nixos-facter -- -o factor.json
```

Copy the report into `system/$host/facter.json`. The install test derives its
boot mode from `uefi.supported` in this file, so a placeholder `{}` makes the
test boot the installed disk with SeaBIOS and hang.

## Wire up the host entry

1. **Hardware profile** — fork the closest match in `hw/` to `hw/<model>.nix`
   and adjust for the machine's quirks.
2. **Host directory** — create `system/$host/` with:
   - `default.nix` — platform and component imports, hostname, hostId,
     persistence, boot loader, user account
   - `disk-config.nix` — Disko storage layout
   - `disk-config-test.nix` — install-test assertions, when the host uses the
     Disko test harness
   - `facter.json` — hardware report generated on the target machine, see
     below
   - `user/<user>/default.nix` — Home Manager configuration
   - `keys/` — public host identities and their fingerprints
3. **Flake wiring** — add both entries to `system/default.nix`:
   - `nixosConfigurations.$host`, including the
     `homeActivationPackage = homeConfigurations."<user>@$host".activationPackage;`
     special argument when the host carries the first-boot Home Manager
     activation unit
   - `homeConfigurations."<user>@$host"`
4. **Record the identities** in `system/$host/keys/README.md`:

```console
ssh-keygen -lf system/$host/keys/ssh_host_ed25519_key.pub
ssh-to-age < system/$host/keys/ssh_host_ed25519_key.pub
```

## Validate

```console
nix eval .#nixosConfigurations.$host.config.system.build.toplevel.drvPath
nix eval .#homeConfigurations."$user@$host".activationPackage.drvPath
```

Then run the disposable-VM validation described in
[VM installation and recovery validation](vm-validation.md):

```console
timeout --signal=INT --kill-after=15s 900s just host-vm-test "$host"
```

Once that passes, continue with
[Preparing a new machine](prepare-new-machine.md).

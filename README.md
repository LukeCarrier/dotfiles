# My dotfiles

An opinionated system (NixOS and macOS) and home configuration, managed with:

- [Nix](https://nixos.wiki/wiki/Nix_Ecosystem)
- [home-manager](https://github.com/nix-community/home-manager)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [sops-nix](https://github.com/Mic92/sops-nix)

---

## Setup

### Secrets

Secrets are managed by SOPS. Place AGE private keys in the file `.sops/keys`, and edit files with `sops $path`.

### macOS

After enabling FileVault on the first login, reboot the machine.

Install Homebrew as appropriate for the architecture:

- For Apple Silicon:
  - Rosetta 2: `sudo softwareupdate --install-rosetta --agree-to-license`
  - aarch64 (native): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
  - x86_64 (via Rosetta): `arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- For Intel:
  - x86_64 (native): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

Run and follow the interactive prompts:

```console
sh <(curl -L https://nixos.org/nix/install)
```

Enable Flakes:

```console
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
```

### NixOS

Don't need to do anything.

## Usage

Apply:

```console
make host home
```

Note that Android and macOS have their own dedicated host targets (`host-android` and `host-darwin` respectively).

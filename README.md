# My dotfiles

Managed with [Home Manager](https://github.com/nix-community/home-manager).

---

## Setup

### macOS

After enabling FileVault on the first login, reboot the machine.

Run and follow the interactive prompts:

```console
sh <(curl -L https://nixos.org/nix/install)
```

Enable Flakes:

```console
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >>~/.config/nix/nix.conf
```

Apply global system configuration:

```console
nix run nix-darwin -- switch --flake ~/Code/LukeCarrier/dotfiles/
```

### NixOS

Don't need to do anything.

## Usage

Apply:

```console
nix run home-manager/release-24.05 -- switch --flake ~/Code/LukeCarrier/dotfiles/#username@host
```

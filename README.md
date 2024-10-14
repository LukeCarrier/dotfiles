# My dotfiles

Managed with [Home Manager](https://github.com/nix-community/home-manager).

---

## Setup

macOS:

```console
```

NixOS:

```console
nix run home-manager/release-24.05 -- init --switch ~/Code/LukeCarrier/dotfiles
```

## Usage

Apply:

```console
nix run home-manager/release-24.05 -- switch --flake ~/Code/LukeCarrier/dotfiles
```

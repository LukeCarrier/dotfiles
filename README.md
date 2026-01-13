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

When things inevitably break, start watching nix-daemon logs in one terminal:

```console
sudo launchctl debug system/org.nixos.nix-daemon --stderr
```

And restart it in another:

```console
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

launchd's interface somehow manages to be even more obtuse than Git's. Think Different strikes again.

### NixOS

Don't need to do anything.

## Usage

Apply:

```console
make host home
```

Note that Android and macOS have their own dedicated host targets (`host-android` and `host-darwin` respectively).

## Rotating credentials

### Checking GitHub personal access tokens

```shell
export GH_TOKEN=(gh auth token)
curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Authorization: Bearer $GH_TOKEN" \
    https://api.github.com/rate_limit
```

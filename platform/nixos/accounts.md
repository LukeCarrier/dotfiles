# homed and sysusers

`accounts.nix` opts a host into systemd-sysusers for system accounts and
systemd-homed for login accounts. It is currently imported by `luke-c0nstruct`
and `luke-w0rkhorse`.

Login accounts are declared through `dotfiles.accounts.users`. Their metadata
and SSH keys are reconciled on boot and configuration switches; `initialPassword`
is used only when creating a new account. Subsequent password changes use `passwd`
or `homectl passwd` and are never reset by provisioning.

Directory-backed homes live at `/home/<user>.homedir`, on the existing persistent
ZFS home dataset. Homed activates them at `/home/<user>` when the user logs in.
The persistent `/var/lib/systemd` directory contains homed's signed account
records and signing keys, as well as systemd's credential key. `/etc/shadow` is
regenerated for system accounts rather than persisted as a file mount.

## Existing installations

Install the new generation for the next boot rather than switching while logged
in. For example, on w0rkhorse:

```sh
sudo nixos-rebuild boot --flake .#luke-w0rkhorse
sudo reboot
```

On the first boot, `homed-accounts.service` migrates the existing home to its
backing directory and registers the account with the existing UID and password.
It uses the legacy `/persist/etc/shadow` if the root rollback has already removed
the old account databases. Password aging and account expiration are retained.
Unsupported password states fail migration rather than falling back to the
bootstrap password.

The migration refuses to move a home while processes with that UID are running.
It stores a root-only checkpoint and any available classic account databases in
`/var/lib/systemd/home-migration`, so an interrupted migration can be retried:

```sh
sudo systemctl restart homed-accounts.service
sudo journalctl -u homed-accounts.service
```

Homed uses a private primary group with GID equal to UID. Existing file ownership
is preserved during the move; the previous `users` group still exists. Legacy
system-account UID/GID allocations are imported into sysusers' persistent marker
files before sysusers runs.

## First login

Fresh installs automatically create the declared account with its bootstrap
password. A home staged before first boot, such as the sops age key written by
`just host-install`, is adopted with the bootstrap password when no classic
account exists in `/etc/passwd`, either shadow file, or `/var/lib/nixos/uid-map`. Home Manager activation runs as a user service on first login. A
completion marker is written only after activation succeeds; failures remain
retryable. If a Home Manager profile already exists, its current generation is
activated instead of replacing it with the bootstrap generation.

SSH keys are supplied through systemd-userdb. An inactive homed home still needs
its password to activate: interactive SSH can use systemd's fallback-shell
prompt after key authentication. Key-only unattended commands and SFTP should
use an already activated home; an SSH key alone cannot activate it.

## Verification

The focused VM test covers fresh provisioning, adoption of a pre-staged home
with AccountsService enumeration, real PAM login and `passwd`,
password persistence across reboot, metadata and key updates, logged-in migration
refusal, interrupted migration recovery, password aging, and stable system IDs.

```sh
nix build --no-link --impure --expr '
  let f = builtins.getFlake ("path:" + toString ./.);
  in import ./platform/nixos/accounts-test.nix {
    pkgs = f.nixosConfigurations.luke-w0rkhorse.pkgs;
    inputs = { inherit (f.inputs) impermanence; };
  }
'
```

The host installation tests additionally check password persistence through ZFS
root rollback and first-login Home Manager activation.

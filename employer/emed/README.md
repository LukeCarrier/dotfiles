# eMed

eMed-specific Nix configuration.

## Security and compliance

The Cyberhaven and Falcon Sensor packaging depends on a `.deb` files being pre-seeded in the Nix store, as the binaries for these are not made publicly available.

### Deploying Cyberhaven

1. Obtain the Cyberhaven `.deb` file (e.g.
   `Cyberhaven-26.03.03.141-ef2a88.deb`) from security and place it under
   `vendor/cyberhaven/`. The filename encodes the version (`26.03.03.141`) and
   short git ref (`ef2a88`) — both are needed for the overlay.
2. Put it in the Nix store so that `fetchurl` doesn't need to actually hit the
   Cyberhaven distribution URL (the upstream link is a Google Drive folder
   that requires interactive auth):
   ```console
   $ nix-store --add-fixed sha256 vendor/cyberhaven/Cyberhaven-26.03.03.141-ef2a88.deb
   /nix/store/l2ykvkac6mfsj5l3943mff14giflzwjj-Cyberhaven-26.03.03.141-ef2a88.deb
   ```
   The `l2ykvk…` component of that store path is the *store path hash* (160
   bits, base32) — **do not** paste this into `fetchurl`'s `hash`/`sha256`
   field. It is not a sha256.
3. Compute the file's actual sha256 in SRI form:
   ```console
   $ nix-hash --type sha256 --flat --sri vendor/cyberhaven/Cyberhaven-26.03.03.141-ef2a88.deb
   sha256-QP2OIKYI03nclno85kFXwZRuB/KaIoMtN9RTXxpt45w=
   ```
4. Update the `version`, `name`, `url` and `hash` fields in the overlay
   providing `cyberhaven` and `cyberhaven-unwrapped` in `flake.nix` with the
   new version/ref pair (e.g. `26.03.03.141-ef2a88`), filename, download URL,
   and the SRI hash from step 3.
5. The Cyberhaven `installToken` in `employer/emed/nixos.nix` is a short-lived
   JWT (decode the middle segment to read its `exp` claim). When it expires,
   fetch a fresh one from the Cyberhaven console and replace the value.

### Deploying Crowdstrike Falcon Sensor

1. Obtain the Crowdstrike Falcon Sensor `.deb` file (e.g.
   `falcon-sensor_7.36.0-18909_amd64.deb`) from security and place it under
   `vendor/crowdstrike/`.
2. Put it in the Nix store so `fetchurl` doesn't need to actually hit the
   CrowdStrike API (the embedded CSRF token will eventually expire):
   ```console
   $ nix-store --add-fixed sha256 vendor/crowdstrike/falcon-sensor_7.36.0-18909_amd64.deb
   /nix/store/h9vl0n3ra558l8qrm0wagxn7f1k1l1rn-falcon-sensor_7.36.0-18909_amd64.deb
   ```
   The `h9vl0n…` component of that store path is the *store path hash* (160
   bits, base32) — **do not** paste this into `fetchurl`'s `hash`/`sha256`
   field. It is not a sha256.
3. Compute the file's actual sha256 in SRI form:
   ```console
   $ nix-hash --type sha256 --flat --sri vendor/crowdstrike/falcon-sensor_7.36.0-18909_amd64.deb
   sha256-D70fSI5Ms2qN8+BVyjYtK75IgT8QeiDqCt95+lqBvP0=
   ```
4. Update the `name`, `url` and `hash` fields in the overlay providing
   `falcon-sensor` and `falcon-sensor-unwrapped` in `flake.nix` with the new
   filename, download URL (from the CrowdStrike sensor download page), and
   the SRI hash from step 3.

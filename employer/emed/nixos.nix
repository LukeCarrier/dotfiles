{ config, lib, ... }:
{
  dotfiles.persistence.directories = lib.optional config.emed.securityAgents.enable "/var/lib/cyberhaven";

  # Cyberhaven and Falcon Sensor packaging/wiring live in
  # emed-nix's nixosModules.emed-security-baseline (imported by each host's
  # default.nix); this just switches it on. See employer/emed/README.md for
  # how to bump the vendored .deb versions.
  emed.securityAgents.enable = true;
  emed.blockUsbStorage = true;

  # AWS Client VPN.
  programs.aws-cvpn.enable = true;

  # VPN certificate files — written to /run/secrets, readable by root only so
  # NetworkManager can load them from the keyfile profile in emed-nix.nixosModules.aws-cvpn.
  sops.secrets = {
    vpn-identity-main-ca = {
      key = "vpn/identity/main/ca";
      mode = "0400";
    };
    vpn-identity-main-cert = {
      key = "vpn/identity/main/cert";
      mode = "0400";
    };
    vpn-identity-main-key = {
      key = "vpn/identity/main/key";
      mode = "0400";
    };
  };
}

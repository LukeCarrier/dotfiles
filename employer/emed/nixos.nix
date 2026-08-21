{
  # Cyberhaven and Falcon Sensor packaging/wiring live in
  # emed-nix's nixosModules.emed-security-baseline (imported by each host's
  # default.nix); this just switches it on. See employer/emed/README.md for
  # how to bump the vendored .deb versions.
  emed.securityAgents.enable = true;
}

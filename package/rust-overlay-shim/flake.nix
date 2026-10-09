{
  description = "Minimal rust-overlay stand-in providing rust-bin.stable.latest from nixpkgs";

  outputs = _: {
    overlays.default = import ./overlay.nix;
  };
}

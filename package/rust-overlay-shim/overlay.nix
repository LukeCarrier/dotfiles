# Consumers (ashell, nirivana, tardy, wpaperd) only touch
# `rust-bin.stable.latest.default` as a combined cargo+rustc toolchain drv,
# for buildInputs entries and makeRustPlatform { cargo = tc; rustc = tc; }.
# Backing it with nixpkgs' own toolchain skips rust-overlay's
# mk-aggregated toolchain assembly during evaluation.
final: prev:
let
  toolchain = prev.symlinkJoin {
    name = "rust-toolchain-stable";
    paths = with prev; [
      cargo
      clippy
      rustc
      rustfmt
    ];
    # buildRustPackage inspects these on its rustc argument.
    passthru = {
      targetPlatforms = prev.rustc.targetPlatforms;
      badTargetPlatforms = prev.rustc.badTargetPlatforms;
    };
  };
in
{
  rust-bin.stable.latest = {
    default = toolchain;
    minimal = toolchain;
  };
}

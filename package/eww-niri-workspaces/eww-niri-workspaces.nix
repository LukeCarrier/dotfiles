{
  pkgs,
  rustPlatform,
  fetchFromGitHub,
  ewwNiriWorkspaces,
}:
rustPlatform.buildRustPackage rec {
  pname = "eww-niri-workspaces";
  version = ewwNiriWorkspaces.version;

  src = fetchFromGitHub {
    owner = "druskus20";
    repo = pname;
    rev = ewwNiriWorkspaces.rev;
    hash = ewwNiriWorkspaces.hash;
  };

  cargoHash = ewwNiriWorkspaces.cargoHash;
}

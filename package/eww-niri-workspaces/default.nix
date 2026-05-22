{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "eww-niri-workspaces";
  # FIXME: there are currently no tags available :-(
  version = "0.0.0-refs/heads/main";

  src = fetchFromGitHub {
    owner = "LukeCarrier";
    repo = "eww-niri-workspaces";
    rev = "refs/heads/main";
    hash = "sha256-w/qGm7eOIhN+Uzj5pFRWk3jLcL8ABo3SPzksOBtYgwM=";
  };

  cargoHash = "sha256-45X5XrDC74znu78cKpsJ32OBpGiRNRXJ597/+c/Hcpk=";
})

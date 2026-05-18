{
  ...
}:
{
  imports = [
    ../../platform/android/common.nix
  ];

  sops.defaultSopsFile = ../../secrets/personal.yaml;

  environment.packages = [ ];
}

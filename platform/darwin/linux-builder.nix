{ ... }:
{
  nix = {
    linux-builder = {
      enable = true;

      ephemeral = true;
      maxJobs = 4;
      supportedFeatures = [ "kvm" "benchmark" "big-parallel" "nixos-test" ];
    };

    settings.trusted-users = [ "@admin" ];
  };

  launchd.daemons.linux-builder.serviceConfig = {
    StandardOutPath = "/var/log/darwin-builder.log";
    StandardErrorPath = "/var/log/darwin-builder.log";
  };
}

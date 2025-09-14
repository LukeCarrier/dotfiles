{ config, ... }:
{
  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  sops = {
    secrets.nix-github = {
      sopsFile = ../../secrets/personal.yaml;
      format = "yaml";
      key = "nix/github";
    };

    templates."nix-github".content = ''
      GITHUB_TOKEN=${config.sops.placeholder.nix-github}
    '';
  };

  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = config.sops.templates.nix-github.path;

  nix = {
    enable = true;

    gc = {
      automatic = true;
      dates = [
        "02:00"
      ];
      options = "--delete-older-than 30d";
    };

    optimise = {
      automatic = true;
      dates = [
        "03:00"
      ];
    };

    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}

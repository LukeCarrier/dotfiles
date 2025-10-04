{ config, lib, ... }:
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
      sopsFile = lib.mkDefault ../../secrets/personal.yaml;
      format = "yaml";
      key = "nix/github";
    };

    templates."nix-access-tokens".content = ''
      access-tokens = "github.com:${config.sops.placeholder.nix-github}"
    '';
  };

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

    extraOptions = ''
      !include ${config.sops.templates.nix-access-tokens.path}
    '';
  };
}

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
      format = "yaml";
      key = "nix/github";
    };

    templates."nix-access-tokens".content = ''
      access-tokens = github.com=${config.sops.placeholder.nix-github}
    '';

    templates."nix-netrc" = {
      content = ''
        machine github.com
        login api
        password ${config.sops.placeholder.nix-github}
        machine codeload.github.com
        login api
        password ${config.sops.placeholder.nix-github}
      '';
      mode = "0400";
      owner = "root";
    };
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
      netrc-file = ${config.sops.templates.nix-netrc.path}
    '';
  };
}

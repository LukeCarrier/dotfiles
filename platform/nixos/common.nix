{ ... }:
{
  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
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

    settings.experimental-features = [ "nix-command" "flakes" ];
  };
}

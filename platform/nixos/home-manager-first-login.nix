{ config, homeActivationPackage, lib, pkgs, ... }:
{
  programs.dconf.enable = true;

  systemd.user.services.home-manager-lukecarrier-first-boot = {
    description = "Activate Home Manager on the first login of lukecarrier";
    wantedBy = [ "default.target" ];
    unitConfig = {
      ConditionUser = "lukecarrier";
      ConditionPathExists = "!/home/lukecarrier/.local/state/home-manager/first-login-activated";
    };
    environment = {
      HOME = "/home/lukecarrier";
      USER = "lukecarrier";
      LOGNAME = "lukecarrier";
      XDG_DATA_DIRS = "${pkgs.dconf}/share:/home/lukecarrier/.nix-profile/share:/run/current-system/sw/share";
    };
    serviceConfig.Type = "oneshot";
    script = ''
      export PATH=${lib.makeBinPath [ pkgs.coreutils config.nix.package ]}:$PATH
      profile="$HOME/.local/state/nix/profiles/home-manager"
      if [ -x "$profile/activate" ]; then
        "$profile/activate"
      else
        ${homeActivationPackage}/activate
      fi
      mkdir -p "$HOME/.local/state/home-manager"
      touch "$HOME/.local/state/home-manager/first-login-activated"
    '';
  };
}

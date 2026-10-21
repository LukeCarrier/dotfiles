{ config, lib, ... }:
let
  cfg = config.dotfiles.accounts;
  # Rootless containers need subordinate IDs inside systemd's container range
  # (0x80000-0x6fff0000): homed UID-shifts home mounts to expose only that range
  # alongside the user's own IDs. Cross-check with `userdbctl` ("begin container
  # users"); see https://rootlesscontaine.rs/getting-started/common/subuid/
  containerRangeStart = 524288;
  containerRangeEnd = 1879048191;
  subordinateCount = 65536;
  subordinateStart = uid: containerRangeStart + uid * subordinateCount;
in
{
  options.dotfiles.accounts.users = lib.mkOption {
    default = { };
    description = "Login accounts managed by systemd-homed.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        uid = lib.mkOption { type = lib.types.ints.between 1000 60000; };
        description = lib.mkOption { type = lib.types.str; default = ""; };
        shell = lib.mkOption {
          type = lib.types.either lib.types.str lib.types.package;
          default = config.users.defaultUserShell;
        };
        extraGroups = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
        authorizedKeys = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
        initialPassword = lib.mkOption {
          type = lib.types.str;
          description = "Bootstrap password used only when creating a new home.";
        };
      };
    });
  };

  config = {
    assertions = lib.mapAttrsToList (name: user: {
      assertion = subordinateStart user.uid + subordinateCount - 1 <= containerRangeEnd;
      message = "dotfiles.accounts.users.${name}: subordinate ID range runs past systemd's container range";
    }) cfg.users;

    systemd.sysusers.enable = true;
    users.mutableUsers = true;
    services.homed = {
      enable = true;
      promptOnFirstBoot = false;
      settings.Home.DefaultStorage = "directory";
    };
    services.userdbd.silenceHighSystemUsers = true;
  };
}

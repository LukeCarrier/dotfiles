{ config, lib, pkgs, utils, ... }:
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
  users = lib.mapAttrs (name: user: {
    inherit (user) initialPassword;
    record = {
      userName = name;
      inherit (user) uid;
      realName = user.description;
      shell = utils.toShellPath user.shell;
      memberOf = user.extraGroups;
      privileged.sshAuthorizedKeys = user.authorizedKeys;
      storage = "directory";
      homeDirectory = "/home/${name}";
      imagePath = "/home/${name}.homedir";
    };
    subUidRanges = [ { startUid = subordinateStart user.uid; count = subordinateCount; } ];
    subGidRanges = [ { startGid = subordinateStart user.uid; count = subordinateCount; } ];
  }) cfg.users;
  userConfig = pkgs.writeText "homed-users.json" (builtins.toJSON {
    inherit users;
    legacyShadow = "${config.dotfiles.persistence.root}/etc/shadow";
    systemUsers = builtins.attrNames config.users.users;
    systemGroups = builtins.attrNames config.users.groups;
  });
  manageAccounts = pkgs.writeShellApplication {
    name = "manage-homed-accounts";
    runtimeInputs = [ config.systemd.package pkgs.glibc.bin pkgs.mkpasswd ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./accounts.py} ${userConfig} "$@"
    '';
  };
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

    systemd.services = {
      systemd-sysusers = {
        unitConfig.RequiresMountsFor = [ "/var/lib/nixos" ];
        serviceConfig.ExecStartPre = [ "${lib.getExe manageAccounts} import-ids" ];
      };

      homed-accounts = {
        description = "Provision and migrate systemd-homed login accounts";
        wantedBy = [ "multi-user.target" ];
        requires = [ "systemd-homed.service" "systemd-sysusers.service" ];
        after = [ "systemd-homed.service" "systemd-sysusers.service" ];
        before = [ "systemd-user-sessions.service" "sshd.service" "greetd.service" ];
        restartTriggers = [ userConfig ];
        unitConfig.RequiresMountsFor = [ "/home" "/var/lib/systemd" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "systemd/home-migration";
          StateDirectoryMode = "0700";
          UMask = "0077";
          ExecStart = "${lib.getExe manageAccounts} provision";
        };
      };
    };
  };
}

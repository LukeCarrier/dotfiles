{ config, lib, pkgs, utils, ... }:
let
  cfg = config.dotfiles.accounts;
  # ExecCondition semantics: 1 skips the run, 255 fails the unit.
  requireActiveHomes = pkgs.writeShellApplication {
    name = "nix-gc-require-active-homes";
    runtimeInputs = [ config.systemd.package pkgs.jq ];
    text = ''
      homes=$(homectl list --json=short) || exit 255
      inactive=$(jq -r '.[] | select(.state != "active") | "\(.name) (\(.state))"' <<<"$homes") || exit 255
      if [[ -n $inactive ]]; then
        printf 'Not collecting garbage; GC roots in these homes would be dropped as stale:\n%s\n' "$inactive"
        exit 1
      fi
    '';
  };
  # Rootless containers need subordinate IDs inside systemd's container range
  # (0x80000-0x6fff0000): homed UID-shifts home mounts to expose only that range
  # alongside the user's own IDs. Cross-check with `userdbctl` ("begin container
  # users"); see https://rootlesscontaine.rs/getting-started/common/subuid/
  containerRangeStart = 524288;
  containerRangeEnd = 1879048191;
  subordinateCount = 65536;
  subordinateStart = uid: containerRangeStart + uid * subordinateCount;
  # homed accounts don't appear in `users.users`, so NixOS never generates
  # /etc/subuid or /etc/subgid. Rootlesskit needs both as real files (not
  # symlinks), so write them with tmpfiles rather than `environment.etc`.
  subordinateIds =
    lib.concatStringsSep "\\n" (
      lib.mapAttrsToList (
        name: user: "${name}:${toString (subordinateStart user.uid)}:${toString subordinateCount}"
      ) cfg.users
    )
    + "\\n";
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

    systemd.tmpfiles.rules = [
      "f+ /etc/subuid 0644 root root - ${subordinateIds}"
      "f+ /etc/subgid 0644 root root - ${subordinateIds}"
    ];

    systemd.sysusers.enable = true;
    users.mutableUsers = true;
    services.homed = {
      enable = true;
      promptOnFirstBoot = false;
      settings.Home.DefaultStorage = "directory";
    };
    services.userdbd.silenceHighSystemUsers = true;

    systemd.services.systemd-homed = lib.mkMerge [
      # homed reads /etc/machine-id at startup. The impermanence bind mount for
      # that file is torn down and recreated during activation, so order homed
      # after the mount to avoid it starting with no machine ID.
      (lib.mkIf (config.services.homed.enable && config.dotfiles.persistence.enable) {
        after = [
          "persist-${utils.escapeSystemdPath "${config.dotfiles.persistence.root}/etc/machine-id"}.service"
        ];
      })

      # systemd-homed-activate's ExecStop is `homectl deactivate-all`, and
      # systemd-homed restarting drops every user record for a moment. A
      # switch-to-configuration run that restarts either one therefore tears
      # down the active home and every user service that resolves the user
      # mid-switch (rootless docker, xdg-document-portal, ...). Skip them on
      # switch; a systemd upgrade picks the new units up at the next boot.
      (lib.mkIf config.services.homed.enable {
        restartIfChanged = false;
      })
    ];
    systemd.services.systemd-homed-activate.restartIfChanged = lib.mkIf config.services.homed.enable false;

    # A homed home only exists at /home/<user> while it's active. Nix deletes
    # indirect GC roots whose target is missing, then collects their closures,
    # so collecting with an inactive home (e.g. nix-gc.timer catching up at
    # boot, before login) destroys every Home Manager generation, profile and
    # direnv root inside it.
    systemd.services.nix-gc = lib.mkIf (config.nix.enable && config.services.homed.enable) {
      wants = [ "systemd-homed.service" ];
      after = [ "systemd-homed.service" ];
      serviceConfig.ExecCondition = lib.getExe requireActiveHomes;
    };
  };
}

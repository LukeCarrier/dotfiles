{ config, inputs, lib, ... }:
let
  cfg = config.dotfiles.persistence;
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.dotfiles.persistence = {
    enable = lib.mkEnableOption "persistent state for an impermanent root";

    root = lib.mkOption {
      type = lib.types.strMatching "/.+";
      default = "/persist";
      description = "Mount point containing persistent system state.";
    };

    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories contributed by modules to persistent storage.";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Files contributed by modules to persistent storage.";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.root}.neededForBoot = true;
    environment.persistence.${cfg.root} = {
      hideMounts = true;
      inherit (cfg) directories files;
    };
  };
}

{ lib, pkgs, ... }:
let
  inherit (lib) getExe getExe';

  powerprofilesctl = getExe' pkgs.power-profiles-daemon "powerprofilesctl";

  # ZFS 2.4.4 doesn't support Linux 7.3 yet. Backport the upstream 7.3
  # compatibility changes (openzfs/zfs#19082) until nixpkgs ships a release
  # that includes them.
  linuxPackages = pkgs.linuxPackages_latest;
  zfsModule = linuxPackages.zfs_2_4.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../package/zfs/linux-7.3.patch ];
    configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-linux-experimental" ];
    meta = old.meta // { broken = false; };
  });

  resetCharging = pkgs.writeShellScriptBin "thinkpad-l14-reset-charging" ''
    set -euo pipefail
    ${pkgs.kmod}/bin/modprobe -r ucsi_acpi
    ${pkgs.kmod}/bin/modprobe ucsi_acpi
  '';

  platformProfileSync = pkgs.writeShellScriptBin "platform-profile-sync" ''
    profile="$(${powerprofilesctl} get 2>/dev/null)" || exit 0
    case "$profile" in
      power-saver) profile=low-power ;;
      balanced | performance) ;;
      *) exit 0 ;;
    esac

    sysfs=/sys/firmware/acpi/platform_profile
    [ -e "$sysfs" ] || exit 0
    [ "$(cat "$sysfs")" = "$profile" ] || echo "$profile" >"$sysfs"
  '';
in
{
  imports = [
    ../component/bolt/nixos.nix
    ../component/fwupd/nixos.nix
  ];

  environment.systemPackages = [ resetCharging ];

  boot = {
    kernelPackages = linuxPackages;
    zfs.modulePackage = zfsModule;

    kernelPatches = [
      {
        name = "ucsi-init-retry";
        patch = ../package/linux/ucsi-init-retry-7.3.patch;
      }
    ];
    # Wait for the GPU to read DPRX instead of tearing down the DP tunnel.
    kernelParams = [ "thunderbolt.dprx_timeout=-1" ];
  };

  services.acpid = {
    enable = true;
  };

  # Without a daemon owning the ACPI platform profile, DYTC leaves it at
  # low-power indefinitely, which clamps the package to a 10W PL1 via the MMIO
  # RAPL interface -- below this chip's 15W base TDP. Selecting balanced raises
  # it to 40W.
  services.power-profiles-daemon.enable = true;

  # The module only adds the package to systemd.packages, which links ppd's
  # unit in without honouring its [Install] section, so nothing would start it
  # at boot. Point it at graphical.target, matching upstream's WantedBy; it
  # cannot be multi-user.target because ppd orders itself After=multi-user.
  systemd.services.power-profiles-daemon.wantedBy = [ "graphical.target" ];

  # ppd only writes the ACPI platform profile when the profile *changes*; at
  # boot it restores its saved profile without rewriting, so DYTC stays clamped
  # at low-power until the user next switches. Re-assert it once ppd is up.
  #
  # Pulled in by ppd rather than multi-user.target: ppd 0.30 orders itself
  # After=multi-user.target, and targets implicitly order themselves after
  # everything they Wants, so wantedBy multi-user.target closes an ordering
  # cycle that systemd breaks by deleting this service's start job.
  systemd.services.platform-profile-sync = {
    description = "Re-assert power-profiles-daemon's profile on the ACPI platform profile";
    wantedBy = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = getExe platformProfileSync;
    };
  };

  # intel_pstate runs in active mode here, which only offers powersave and
  # performance, so the shared ondemand setting cannot apply. Drop it rather
  # than have cpufreq.service fail and a cpufreq_ondemand modprobe miss on
  # every boot; HWP with energy_performance_preference=performance is what we
  # want on this CPU regardless.
  powerManagement.cpuFreqGovernor = lib.mkForce null;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_start_threshold}="75"
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_end_threshold}="80"
  '';

}

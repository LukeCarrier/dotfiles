{ lib, pkgs, ... }:
let
  inherit (lib) getExe getExe';

  powerprofilesctl = getExe' pkgs.power-profiles-daemon "powerprofilesctl";

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

  boot = {
    # ZFS only supports up to 7.2, so stay one release behind latest (7.3).
    kernelPackages = pkgs.linuxPackages_7_2;

    # Canonical's "thunderbolt: Retry DP tunnel setup on DPRX negotiation
    # failure" (posted to linux-usb 2026-04-30, not yet upstream). Without it
    # the driver permanently drops the DP IN adapter on the first DPRX failure,
    # so the dock's displays never come back after a reconnect.
    kernelPatches = [
      {
        name = "thunderbolt-dprx-retry";
        patch = ../package/linux/thunderbolt-dprx-retry.patch;
      }
    ];

    # KIOXIA Exceria Basic (1e0f:003b, fw A1RA0104) has repeatedly failed with
    # `nvme0n1: I/O Cmd ... I/O Error` + uncorrectable CmpltTO AER storms when
    # the controller is allowed non-operational power states. PS4 advertises
    # a 32 ms exit latency; PS3's 1.2 ms exit latency still causes completion
    # timeouts on this platform. latency_us=0 pins the drive to PS0-PS2 and
    # has been stable since.
    #
    # pcie_aspm=off disables PCIe link power management for the same reason;
    # Data Link Layer Timeout/Rollover AER errors were present on the RP.
    #
    # Bisect plan, once stable long enough to rely on it:
    #  1. Drop pcie_aspm=off, keep pcie_aspm.policy=performance + latency=0.
    #     If stable, ASPM off may be overkill.
    #  2. Try latency_us=2000 (PS3 allowed). If the hang returns, PS3 is the
    #     trigger; 0 remains justified. If stable, the default 25000 default
    #     was the only problem and ASPM off can likely go too.
    #  3. Report an upstream NVMe quirk (NVME_QUIRK_NO_DEEPEST_PS) — the drive
    #     is advertising legal-but-broken exit latencies.
    kernelParams = [
      "nvme_core.default_ps_max_latency_us=0"
      "pcie_aspm.policy=performance"
      "pcie_aspm=off"

      # Work around DP-over-USB4/dock detection failures on this platform; see
      # the DP tunnel DPRX negotiation bug in drivers/thunderbolt/tb.c.
      "i915.enable_dp_mst=0"

      # Don't tear the DP tunnel down before the GPU driver has read DPRX
      # (-1 = wait forever; default is 12000 ms).
      "thunderbolt.dprx_timeout=-1"
    ];
  };

  services.acpid = {
    enable = true;
  };

  # Without a daemon owning the ACPI platform profile, the firmware leaves it
  # at low-power and clamps the package indefinitely. Selecting balanced
  # restores the full power limit.
  services.power-profiles-daemon.enable = true;

  # ppd only writes the ACPI platform profile when the profile *changes*; at
  # boot it restores its saved profile without rewriting, so DYTC stays clamped
  # at low-power until the user next switches. Re-assert it once ppd is up.
  systemd.services.platform-profile-sync = {
    description = "Re-assert power-profiles-daemon's profile on the ACPI platform profile";
    wantedBy = [ "multi-user.target" ];
    wants = [ "power-profiles-daemon.service" ];
    after = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = getExe platformProfileSync;
    };
  };

  # graphical.nix pins ondemand globally, but the active pstate drivers
  # (intel_pstate/active, amd-pstate/active) don't expose it. Drop the governor
  # rather than have cpufreq.service fail with an ondemand modprobe miss on
  # every boot; energy_performance_preference is what we want anyway.
  powerManagement.cpuFreqGovernor = lib.mkForce null;

  # Cap battery charge at 80% to reduce wear.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_start_threshold}="75"
    ACTION=="add", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_NAME}=="BAT0", ATTR{charge_control_end_threshold}="80"
  '';

}

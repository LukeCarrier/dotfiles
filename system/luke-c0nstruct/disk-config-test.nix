{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../platform/nixos/disko-install-test.nix ];

  assertions = [
    {
      assertion = builtins.elem "systemd-hibernate-resume.service" config.boot.initrd.systemd.services.zfs-import-c0nstruct.after;
      message = "ZFS import must wait for the hibernation resume attempt";
    }
  ];

  disko.tests.bootCommands = ''
    machine.wait_for_console_text("passphrase for disk")
    time.sleep(1)
    machine.send_chars("disko\n")
  '';
  disko.tests.enableOCR = true;
  disko.tests.extraChecks = ''
    import json

    def journal_timestamp(unit, pattern):
        entries = machine.succeed(f"journalctl -b -u {unit} -o json").splitlines()
        matches = [json.loads(entry) for entry in entries if pattern in json.loads(entry).get("MESSAGE", "")]
        assert matches, f"missing journal event for {unit}: {pattern}"
        return min(int(entry["__MONOTONIC_TIMESTAMP"]) for entry in matches)

    machine.succeed("test -c /dev/tpmrm0")
    machine.succeed("test $(cat /sys/class/tpm/tpm0/tpm_version_major) -eq 2")
    efi_token_hash = machine.succeed("sha256sum /sys/firmware/efi/efivars/LoaderSystemToken-* | cut -d' ' -f1").strip()
    machine.succeed("test $(blockdev --getsize64 /dev/vda) -eq $((128 * 1024 * 1024 * 1024))")
    machine.succeed("test $(blockdev --getsize64 /dev/vda1) -eq $((1024 * 1024 * 1024))")
    machine.succeed("test $(blkid -s TYPE -o value /dev/vda1) = vfat")
    machine.succeed("cryptsetup luksDump /dev/vda2 | grep -Eq '^Version:[[:space:]]+2$'")
    machine.succeed("pvs --noheadings -o pv_name,vg_name | grep -Eq '/dev/mapper/cryptroot[[:space:]]+c0nstruct'")
    machine.succeed("lvs --noheadings -o lv_name,vg_name | grep -Eq 'swap[[:space:]]+c0nstruct'")
    machine.succeed("lvs --noheadings -o lv_name,vg_name | grep -Eq 'zfs[[:space:]]+c0nstruct'")
    machine.succeed("test $(blockdev --getsize64 /dev/c0nstruct/swap) -eq $((64 * 1024 * 1024 * 1024))")
    machine.succeed("swapon --show=NAME --noheadings | xargs readlink -f | grep -Fxq $(readlink -f /dev/c0nstruct/swap)")
    machine.succeed("zpool status -x c0nstruct")
    assert journal_timestamp("systemd-hibernate-resume.service", "Unable to resume") < journal_timestamp("zfs-import-c0nstruct.service", "importing ZFS pool")
    machine.succeed("zfs list -H -t snapshot -o name c0nstruct/root@blank")
    machine.succeed("test $(findmnt -nro SOURCE --mountpoint /) = c0nstruct/root")
    machine.succeed("test $(findmnt -nro SOURCE --mountpoint /nix) = c0nstruct/nix")
    machine.succeed("test $(findmnt -nro SOURCE --mountpoint /home) = c0nstruct/home")
    machine.succeed("test $(findmnt -nro SOURCE --mountpoint /persist) = c0nstruct/persist")
    machine.wait_for_unit("homed-accounts.service")
    machine.succeed("busctl call org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts ListCachedUsers | grep -F /org/freedesktop/Accounts/User1000")
    machine.succeed("PASSWORD=nixos homectl activate --no-ask-password lukecarrier")
    machine.succeed("grep -Fxq seeded-age-key /home/lukecarrier/.config/sops/age/keys.txt")
    machine.succeed("test $(stat -c %U:%a /home/lukecarrier/.config/sops/age/keys.txt) = lukecarrier:600")
    machine.succeed("systemctl start user@1000.service")
    machine.wait_until_succeeds("test -L /home/lukecarrier/.local/state/nix/profiles/home-manager")
    machine.wait_until_succeeds("test -e /home/lukecarrier/.local/state/home-manager/first-login-activated")
    home_manager_profile = machine.succeed("readlink /home/lukecarrier/.local/state/nix/profiles/home-manager").strip()
    machine.succeed("PASSWORD=nixos NEWPASSWORD=disko-user-password homectl passwd lukecarrier")
    machine.succeed("umask 077; printf disko > /persist/it-recovery.key")
    machine.succeed("umask 077; printf userrecovery > /persist/user-recovery.key")
    machine.succeed("test $(stat -c %a /persist/it-recovery.key) = 600")
    machine.succeed("test $(stat -c %a /persist/user-recovery.key) = 600")
    initial_slots = set(json.loads(machine.succeed("cryptsetup luksDump --dump-json-metadata /dev/vda2"))["keyslots"])
    assert len(initial_slots) == 1
    it_recovery_slot = initial_slots.pop()
    machine.succeed("cryptsetup luksAddKey --key-file /persist/it-recovery.key /dev/vda2 /persist/user-recovery.key")
    recovery_slots = set(json.loads(machine.succeed("cryptsetup luksDump --dump-json-metadata /dev/vda2"))["keyslots"])
    user_recovery_slots = recovery_slots - {it_recovery_slot}
    assert len(user_recovery_slots) == 1
    user_recovery_slot = user_recovery_slots.pop()
    machine.succeed(f"cryptsetup open --test-passphrase --key-slot {it_recovery_slot} --key-file /persist/it-recovery.key /dev/vda2")
    machine.succeed(f"cryptsetup open --test-passphrase --key-slot {user_recovery_slot} --key-file /persist/user-recovery.key /dev/vda2")
    machine.fail(f"cryptsetup open --test-passphrase --key-slot {user_recovery_slot} --key-file /persist/it-recovery.key /dev/vda2")
    machine.fail(f"cryptsetup open --test-passphrase --key-slot {it_recovery_slot} --key-file /persist/user-recovery.key /dev/vda2")
    machine.succeed("PASSWORD=userrecovery NEWPIN=123456 systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=4+7+9+12 --tpm2-with-pin=yes /dev/vda2")
    machine.succeed("cryptsetup luksDump --dump-json-metadata /dev/vda2 | grep -q systemd-tpm2")
    machine.succeed("cryptsetup luksDump --dump-json-metadata /dev/vda2 | grep -q '\"tpm2-pin\":true'")
    machine.succeed("touch /home/.persistence-test /persist/.persistence-test")
    machine_id = machine.succeed("cat /etc/machine-id").strip()
    machine.shutdown()

    swtpm_process = restart_swtpm(swtpm_process)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("654321\n")
    machine.wait_for_console_text("Bad PIN.")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_unit("local-fs.target")
    machine.succeed("test -c /dev/tpmrm0")
    machine.succeed("test $(cat /sys/class/tpm/tpm0/tpm_version_major) -eq 2")
    assert machine.succeed("sha256sum /sys/firmware/efi/efivars/LoaderSystemToken-* | cut -d' ' -f1").strip() == efi_token_hash
    machine.succeed("test -e /home/.persistence-test")
    machine.succeed("test -e /persist/.persistence-test")
    assert machine.succeed("cat /etc/machine-id").strip() == machine_id
    machine.wait_for_unit("homed-accounts.service")
    machine.succeed("PASSWORD=disko-user-password homectl activate --no-ask-password lukecarrier")
    machine.succeed("systemctl start user@1000.service")
    machine.wait_until_succeeds("systemctl --user --machine=lukecarrier@.host is-active default.target")
    assert machine.succeed("readlink /home/lukecarrier/.local/state/nix/profiles/home-manager").strip() == home_manager_profile
    machine.succeed("test $(systemctl --user --machine=lukecarrier@.host show -P ConditionResult home-manager-lukecarrier-first-boot.service) = no")
    machine.wait_until_succeeds("test -L /home/lukecarrier/.local/state/nix/profiles/home-manager")
    machine.succeed("test $(systemctl --user --machine=lukecarrier@.host show -P Result home-manager-lukecarrier-first-boot.service) = success")
    machine.succeed("test $(systemctl --user --machine=lukecarrier@.host show -P ExecMainStatus home-manager-lukecarrier-first-boot.service) -eq 0")
    machine.succeed("test -L /home/lukecarrier/.local/state/nix/profiles/home-manager")
    machine.succeed("test -L /home/lukecarrier/.config/niri/config.kdl")
    machine.succeed("test -x /home/lukecarrier/.nix-profile/bin/home-manager")
    machine.succeed("test $(stat -c %U /home/lukecarrier/.local/state/nix/profiles/home-manager) = lukecarrier")

    machine.succeed("sed -i '/^options / s/$/ test-pcr-mismatch=1/' /boot/loader/entries/*.conf")
    machine.shutdown()
    swtpm_process = restart_swtpm(swtpm_process)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_console_text("TPM policy does not match")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_console_text("TPM policy does not match")
    time.sleep(1)
    machine.send_chars("disko\n")
    machine.wait_for_unit("local-fs.target")
    machine.succeed(f"cryptsetup open --test-passphrase --key-slot {it_recovery_slot} --key-file /persist/it-recovery.key /dev/vda2")
    machine.succeed("/run/current-system/bin/switch-to-configuration boot")

    machine.shutdown()
    swtpm_process = restart_swtpm(swtpm_process)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_unit("local-fs.target")

    machine.shutdown()
    swtpm_process = restart_swtpm(swtpm_process, reset_state=True)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_console_text("Esys Finish ErrorCode")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_console_text("passphrase for disk")
    time.sleep(1)
    machine.send_chars("userrecovery\n")
    machine.wait_for_unit("local-fs.target")
    machine.succeed(f"cryptsetup open --test-passphrase --key-slot {user_recovery_slot} --key-file /persist/user-recovery.key /dev/vda2")
    machine.succeed(f"cryptsetup open --test-passphrase --key-slot {it_recovery_slot} --key-file /persist/it-recovery.key /dev/vda2")
    machine.succeed("PASSWORD=userrecovery NEWPIN=123456 systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=4+7+9+12 --tpm2-with-pin=yes /dev/vda2")

    machine.succeed("test $(findmnt -nro FSTYPE --target /nix/store) = zfs")
    machine.succeed("test $(findmnt -nro SOURCE --mountpoint /nix) = c0nstruct/nix")
    machine.succeed("grep -qw disk /sys/power/state")
    machine.succeed("mkdir /run/hibernate-test")
    machine.succeed("mount -t ramfs -o size=1m ramfs /run/hibernate-test")
    machine.succeed("printf resumed > /run/hibernate-test/sentinel")
    machine.succeed("printf resumed > /hibernate-root-sentinel")
    machine.succeed("systemd-run --unit hibernation-sentinel.service --property Type=simple sleep infinity")
    machine.wait_for_unit("hibernation-sentinel.service")
    boot_id = machine.succeed("cat /proc/sys/kernel/random/boot_id").strip()
    sentinel_pid = machine.succeed("systemctl show -P MainPID hibernation-sentinel.service").strip()

    machine.execute("systemctl hibernate >&2 &", check_return=False)
    machine.wait_for_shutdown()

    swtpm_process = restart_swtpm(swtpm_process)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_unit("local-fs.target")
    assert machine.succeed("cat /proc/sys/kernel/random/boot_id").strip() == boot_id
    assert machine.succeed("systemctl show -P MainPID hibernation-sentinel.service").strip() == sentinel_pid
    machine.succeed("grep -Fxq resumed /run/hibernate-test/sentinel")
    machine.succeed("grep -Fxq resumed /hibernate-root-sentinel")
    machine.succeed("zpool status -x c0nstruct")

    machine.succeed("test $(lvs --noheadings -o seg_pe_ranges /dev/c0nstruct/swap | grep -Ec ':0-') -eq 1")
    partition_start = int(machine.succeed("lsblk -no START /dev/vda2").strip()) * 512
    crypt_offset = int(machine.succeed("cryptsetup status cryptroot | awk '/offset:/ {print $2}'").strip()) * 512
    pe_start = int(machine.succeed("pvs --noheadings --units b --nosuffix -o pe_start /dev/mapper/cryptroot").strip())
    swap_ciphertext_offset = partition_start + crypt_offset + pe_start
    failed_resume_boot_id = machine.succeed("cat /proc/sys/kernel/random/boot_id").strip()
    machine.succeed("printf stale > /run/hibernate-test/stale-sentinel")
    machine.execute("systemctl hibernate >&2 &", check_return=False)
    machine.wait_for_shutdown()
    subprocess.run([
        "${pkgs.qemu}/bin/qemu-io", "-f", "qcow2", "-c",
        f"write -P 0x00 {swap_ciphertext_offset} 4096",
        disk_image_paths[0],
    ], check=True)

    swtpm_process = restart_swtpm(swtpm_process)
    machine.start()
    machine.wait_for_console_text("PIN:")
    time.sleep(1)
    machine.send_chars("123456\n")
    machine.wait_for_unit("local-fs.target")
    assert machine.succeed("cat /proc/sys/kernel/random/boot_id").strip() != failed_resume_boot_id
    machine.succeed("test ! -e /run/hibernate-test/stale-sentinel")
    machine.succeed("test ! -e /hibernate-root-sentinel")
    assert journal_timestamp("systemd-hibernate-resume.service", "Unable to resume") < journal_timestamp("zfs-import-c0nstruct.service", "importing ZFS pool")
    machine.succeed("mkswap -f /dev/c0nstruct/swap")
    machine.succeed("swapon /dev/c0nstruct/swap")
    machine.succeed("zpool status -x c0nstruct")
  '';

  disko.tests.extraConfig = {
    boot.initrd.systemd.services.test-pcr-mismatch = {
      after = [ "dev-tpmrm0.device" ];
      before = [ "systemd-cryptsetup@cryptroot.service" ];
      requiredBy = [ "systemd-cryptsetup@cryptroot.service" ];
      path = [ pkgs.tpm2-tools ];
      script = "tpm2_pcrextend 12:sha256=${lib.concatStrings (lib.replicate 64 "0")}";
      serviceConfig.Type = "oneshot";
      unitConfig = {
        ConditionKernelCommandLine = "test-pcr-mismatch";
        DefaultDependencies = false;
      };
    };
    boot.lanzaboote.enable = lib.mkForce false;
    boot.binfmt.emulatedSystems = lib.mkForce [ ];
    boot.loader.systemd-boot.enable = lib.mkOverride 40 true;
    boot.plymouth.enable = lib.mkForce false;
    fonts.packages = lib.mkForce [ ];
    hardware.bluetooth.enable = lib.mkForce false;
    programs = {
      gamescope.enable = lib.mkForce false;
      niri.enable = lib.mkForce false;
    };
    networking = {
      dhcpcd.enable = lib.mkForce false;
      networkmanager.enable = lib.mkForce false;
      useDHCP = lib.mkForce false;
    };
    powerManagement.powerDownCommands = "systemctl --no-block stop backdoor.service";
    powerManagement.resumeCommands = "systemctl --no-block restart backdoor.service";
    services = {
      avahi.enable = lib.mkForce false;
      blueman.enable = lib.mkForce false;
      colord.enable = lib.mkForce false;
      displayManager.regreet.enable = lib.mkForce false;
      flatpak.enable = lib.mkForce false;
      greetd.enable = lib.mkForce false;
      gvfs.enable = lib.mkForce false;
      pipewire.enable = lib.mkForce false;
      printing.enable = lib.mkForce false;
      xserver.enable = lib.mkForce false;
    };
    services.accounts-daemon.enable = lib.mkForce true;
    # Mirrors `just host-install`, which stages the sops age key in the home before first boot.
    systemd.services.seed-home = {
      wantedBy = [ "homed-accounts.service" ];
      before = [ "homed-accounts.service" ];
      unitConfig = {
        ConditionPathExists = [ "!/home/lukecarrier" "!/home/lukecarrier.homedir" ];
        RequiresMountsFor = [ "/home" ];
      };
      serviceConfig.Type = "oneshot";
      script = ''
        umask 077
        install -d -m 700 -o 1000 -g 1000 /home/lukecarrier /home/lukecarrier/.config /home/lukecarrier/.config/sops /home/lukecarrier/.config/sops/age
        echo seeded-age-key > /home/lukecarrier/.config/sops/age/keys.txt
        chown 1000:1000 /home/lukecarrier/.config/sops/age/keys.txt
        chmod 600 /home/lukecarrier/.config/sops/age/keys.txt
      '';
    };
    virtualisation = {
      docker.rootless.enable = lib.mkForce false;
      libvirtd.enable = lib.mkForce false;
    };

    # Production provisioning stages the host identities before activation.
    system.activationScripts.setupSecrets.text = lib.mkForce "";
  };
}

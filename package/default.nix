{
  nixos-images,
  nixpkgs-kexec,
  pkgs,
}:
let
  inherit (pkgs) callPackage;
  kexecKernel = nixpkgs-kexec.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages_latest.kernel;
  networkManagerHandoffModule =
    { lib, pkgs, ... }:
    {
      boot.initrd.systemd.services.restore-state-from-initrd.script = lib.mkAfter ''
        if [[ -d /NetworkManager ]]; then
          install -d -m 700 /sysroot/root/NetworkManager
          cp -aL /NetworkManager/. /sysroot/root/NetworkManager/
        fi
      '';

      systemd.services.NetworkManager.preStart = lib.mkBefore ''
        manifest=/root/NetworkManager/profile.sha256
        name_file=/root/NetworkManager/profile.name
        if [[ -f "$manifest" && -f "$name_file" ]]; then
          profile_name=$(cat "$name_file")
          profile=/root/NetworkManager/system-connections/$profile_name
          expected_hash=$(cat "$manifest")
          if [[ "$profile_name" != */* && -f "$profile" && "$(sha256sum "$profile" | cut -d ' ' -f 1)" == "$expected_hash" ]] && grep -q '^psk=..*' "$profile"; then
            install -d -m 700 /etc/NetworkManager/system-connections
            install -m 600 "$profile" "/etc/NetworkManager/system-connections/$profile_name"
            grep '^uuid=' "$profile" | cut -d= -f2- > /run/installer-wifi.uuid
          else
            echo "Ignoring invalid transferred NetworkManager profile" >&2
          fi
        else
          echo "No transferred NetworkManager profile found" >&2
        fi
      '';

      systemd.services.activate-installer-wifi = {
        after = [ "NetworkManager.service" ];
        requires = [ "NetworkManager.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.networkmanager
        ];
        script = ''
          uuid=$(cat /run/installer-wifi.uuid)
          test -n "$uuid"
          nmcli connection modify uuid "$uuid" connection.autoconnect yes
          for _ in $(seq 1 30); do
            nmcli connection up uuid "$uuid" && exit 0
            sleep 2
          done
          exit 1
        '';
      };
    };
  bootstrap-kexec =
    (pkgs.nixos [
      nixos-images.nixosModules.kexec-installer
      networkManagerHandoffModule
      (
        {
          config,
          lib,
          modulesPath,
          pkgs,
          ...
        }:
        {
          imports = [ (modulesPath + "/profiles/installation-device.nix") ];

          boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kexecKernel);
          boot.supportedFilesystems = [ "zfs" ];
          hardware.enableAllHardware = true;
          hardware.enableRedistributableFirmware = lib.mkForce true;

          networking.networkmanager.enable = lib.mkOverride 40 true;
          networking.wireless.iwd.enable = lib.mkForce false;
          networking.useNetworkd = lib.mkForce false;
          systemd.network.enable = lib.mkForce false;
          systemd.services.restore-network.enable = false;

          system.kexec-installer.name = "nixos-bootstrap-kexec";
          system.build.kexecRun = lib.mkForce (pkgs.runCommand "bootstrap-kexec-run" { } ''
            install -D -m 0755 ${nixos-images}/nix/kexec-installer/kexec-run.sh $out
            substituteInPlace $out \
              --replace-fail '@init@' '${config.system.build.toplevel}/init' \
              --replace-fail '@kernelParams@' '${lib.escapeShellArgs config.boot.kernelParams}' \
              --replace-fail 'mkdir -p ssh' 'mkdir -p ssh NetworkManager/system-connections
active_wifi_uuid=$(nmcli -t -f UUID,TYPE connection show --active | while IFS=: read -r uuid type; do
  if test "$type" = 802-11-wireless || test "$type" = wifi; then
    printf "%s\\n" "$uuid"
    break
  fi
done)
test -n "$active_wifi_uuid"
active_wifi_profile=
for connection_dir in /etc/NetworkManager/system-connections /run/NetworkManager/system-connections; do
  if test -d "$connection_dir"; then
    for profile in "$connection_dir"/*; do
      test -f "$profile" || continue
      if grep -q "^uuid=$active_wifi_uuid$" "$profile"; then
        profile_name=$(basename "$profile")
        install -m 600 "$profile" "NetworkManager/system-connections/$profile_name"
        printf "%s\\n" "$profile_name" > NetworkManager/profile.name
        active_wifi_profile="NetworkManager/system-connections/$profile_name"
        break 2
      fi
    done
  fi
done
if test -z "$active_wifi_profile" || ! grep -q "^psk=..*" "$active_wifi_profile"; then
  echo "The active NetworkManager Wi-Fi profile with its PSK was not found" >&2
  exit 1
fi
sha256sum "$active_wifi_profile" | cut -d " " -f 1 > NetworkManager/profile.sha256' \
              --replace-fail 'find . | cpio -o -H newc | gzip -9 >> "$SCRIPT_DIR/initrd"' 'find . | cpio -o -H newc | gzip -9 >> "$SCRIPT_DIR/initrd"

gpu_address=0000:00:02.0
gpu_driver_link=/sys/bus/pci/devices/$gpu_address/driver
if test -L "$gpu_driver_link"; then
  gpu_driver=$(basename "$(readlink -f "$gpu_driver_link")")
  case "$gpu_driver" in
    i915|xe)
      printf "%s\\n" "$gpu_address" > "/sys/bus/pci/drivers/$gpu_driver/unbind"
      if test -e "$gpu_driver_link"; then
        echo "Failed to unbind $gpu_address from $gpu_driver before kexec" >&2
        exit 1
      fi
      ;;
  esac
fi'
            ${pkgs.shellcheck}/bin/shellcheck $out
          '');

        }
      )
    ]).config.system.build.kexecInstallerTarball;
  bootstrap-kexec-network-test =
    let
      profileName = "Peacehaven Home.nmconnection";
      profile = ''
        [connection]
        id=Peacehaven Home
        uuid=72e56ac1-6a44-4f0e-be74-7cf3ec804f15
        type=wifi

        [wifi]
        mode=infrastructure
        ssid=Peacehaven Home

        [wifi-security]
        key-mgmt=wpa-psk
        psk=test-password

        [ipv4]
        method=auto

        [ipv6]
        method=auto
      '';
    in
    pkgs.testers.runNixOSTest {
      name = "bootstrap-kexec-network-handoff";
      nodes.machine =
        { lib, ... }:
        {
          imports = [ networkManagerHandoffModule ];
          boot.initrd.systemd.enable = true;
          boot.initrd.systemd.contents = {
            "/NetworkManager/profile.name".text = "${profileName}\n";
            "/NetworkManager/profile.sha256".text = "${builtins.hashString "sha256" profile}\n";
            "/NetworkManager/system-connections/${profileName}".text = profile;
          };
          boot.initrd.systemd.services.restore-state-from-initrd = {
            wantedBy = [ "initrd.target" ];
            before = [ "initrd-switch-root.target" ];
            unitConfig = {
              DefaultDependencies = false;
              RequiresMountsFor = "/sysroot";
            };
            serviceConfig.Type = "oneshot";
            script = "true";
          };
          networking.networkmanager.enable = true;
          systemd.services.activate-installer-wifi.enable = lib.mkForce false;
        };
      testScript = ''
        machine.start()
        machine.wait_for_unit("NetworkManager.service")
        profile = "/etc/NetworkManager/system-connections/${profileName}"
        machine.succeed(f"test -f '{profile}'")
        machine.succeed(f"test $(stat -c %a '{profile}') = 600")
        machine.succeed(f"test $(sha256sum '{profile}' | cut -d' ' -f1) = ${builtins.hashString "sha256" profile}")
        machine.succeed("test $(cat /run/installer-wifi.uuid) = 72e56ac1-6a44-4f0e-be74-7cf3ec804f15")
        machine.succeed("systemctl is-active NetworkManager.service")
        machine.succeed("nmcli connection show uuid 72e56ac1-6a44-4f0e-be74-7cf3ec804f15")
      '';
    };
  obsbot-camera-control = callPackage ./obsbot-camera-control { };
in
rec {
  aws-cli-tools = callPackage ./aws-cli-tools { };

  bw-cli-tools = callPackage ./bw-cli-tools { };

  docker-cli-tools = callPackage ./docker-cli-tools { };

  github-cli-tools = callPackage ./github-cli-tools { };

  dotfiles-meta = callPackage ./dotfiles-meta { };

  eww-niri-workspaces = callPackage ./eww-niri-workspaces { };

  excalidraw-mcp-app = callPackage ./excalidraw-mcp-app { };

  floww = callPackage ./floww { };

  ghidra-mcp = callPackage ./ghidra-mcp { };
  ghidra-mcp-plugin = (callPackage ./ghidra-mcp { }).ghidraPlugin;

  goose-cli = callPackage ./goose/goose.nix { };
  goose-desktop = callPackage ./goose/desktop.nix { inherit goose-cli; };

  grafana-mcp = callPackage ./grafana-mcp { };

  hibiki = callPackage ./hibiki { };

  kubernetes-client-tools = callPackage ./kubernetes-client-tools { };

  inherit bootstrap-kexec;
  inherit bootstrap-kexec-network-test;

  mcp-remote = callPackage ./mcp-remote { };

  monaspace-fonts = callPackage ./monaspace-fonts { };

  inherit (pkgs) niri;

  nixos-anywhere = pkgs.nixos-anywhere.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/nixos-anywhere.sh \
        --replace-fail 'declare -a sshArgs=("-o" "IdentitiesOnly=yes" "-i" "$tempDir/nixos-anywhere" "-o" "UserKnownHostsFile=/dev/null" "-o" "StrictHostKeyChecking=no")' \
        'declare -a sshArgs=("-o" "IdentitiesOnly=yes" "-i" "$tempDir/nixos-anywhere")' \
        --replace-fail '  if [[ ''${isInstaller} == "y" ]]; then
    return
  fi
' ""
    '';
  });

  nx-tools = callPackage ./nx-tools { };

  inherit (obsbot-camera-control)
    obsbot-sdk
    obsbot-camera-control-cli
    obsbot-camera-control-gui;

  onepassword-tools = callPackage ./onepassword-tools { };

  rift = callPackage ./rift { };

  stklos = callPackage ./stklos { };

  toon-cli = callPackage ./toon-cli { };

  wireloom-cli = callPackage ./wireloom-cli { };
}

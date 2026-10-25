{
  config,
  lib,
  pkgs,
  utils,
  vmHomeActivation ? null,
  vmHomeUser ? null,
  ...
}:
let
  homeUser = if vmHomeUser == null then null else config.dotfiles.accounts.users.${vmHomeUser};
in
{
  # The host resumes from its ZFS swap LV, which does not exist in the VM.
  boot.resumeDevice = lib.mkForce "";
  swapDevices = lib.mkForce [ ];

  # Provision the same homed account the host uses, then stage the host's Home
  # Manager profile so the first-login service activates it. The sops age key
  # is supplied out-of-band through the shared directory.
  systemd.services.vm-home-setup = lib.mkIf (vmHomeActivation != null && vmHomeUser != null) {
    wantedBy = [ "multi-user.target" ];
    before = [ "greetd.service" ];
    after = [ "systemd-homed.service" ];
    requires = [ "systemd-homed.service" ];
    path = with pkgs; [
      coreutils
      jq
      mkpasswd
      systemd
      util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      user=${lib.escapeShellArg vmHomeUser}
      password=${lib.escapeShellArg homeUser.initialPassword}
      uid=${toString homeUser.uid}

      if ! homectl inspect "$user" >/dev/null 2>&1; then
        hash="$(printf '%s' "$password" | mkpasswd --method=yescrypt --stdin)"
        jq -n \
          --arg userName "$user" \
          --argjson uid "$uid" \
          --arg realName ${lib.escapeShellArg homeUser.description} \
          --arg shell ${lib.escapeShellArg (toString (utils.toShellPath homeUser.shell))} \
          --argjson memberOf ${lib.escapeShellArg (builtins.toJSON homeUser.extraGroups)} \
          --arg hash "$hash" \
          --arg password "$password" \
          '{
            userName: $userName,
            uid: $uid,
            realName: $realName,
            shell: $shell,
            memberOf: $memberOf,
            privileged: { hashedPassword: [ $hash ] },
            secret: { password: [ $password ] },
            storage: "directory",
            homeDirectory: ("/home/" + $userName),
            imagePath: ("/home/" + $userName + ".homedir"),
            enforcePasswordPolicy: false
          }' | homectl create --no-ask-password --identity=-
      fi

      if ! findmnt -n "/home/$user" >/dev/null 2>&1; then
        PASSWORD="$password" homectl activate --no-ask-password "$user"
      fi

      home="/home/$user"
      install -d -m 700 -o "$uid" -g "$uid" \
        "$home/.config" \
        "$home/.local" \
        "$home/.local/state" \
        "$home/.local/state/nix" \
        "$home/.local/state/nix/profiles"
      ln -sfn ${vmHomeActivation} "$home/.local/state/nix/profiles/home-manager"

      if [ -s /tmp/shared/age-keys.txt ]; then
        install -d -m 700 -o "$uid" -g "$uid" "$home/.config/sops/age"
        install -m 600 -o "$uid" -g "$uid" /tmp/shared/age-keys.txt "$home/.config/sops/age/keys.txt"
      fi

      # Activate the profile before the graphical session starts; otherwise niri
      # comes up before the first-login service has written its config.
      install -d -m 700 -o "$uid" -g "$uid" "/run/user/$uid"
      runuser -u "$user" -- env \
        HOME="$home" USER="$user" LOGNAME="$user" \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        "${vmHomeActivation}/activate" || true

      # The account did not exist when AccountsService first enumerated users.
      systemctl try-restart accounts-daemon.service
    '';
  };

  virtualisation.vmVariant.virtualisation = {
    memorySize = 8192;
    cores = 4;
    qemu.options = [
      "-device"
      "virtio-vga-gl"
      "-display"
      "gtk,gl=on"
    ];
  };
}

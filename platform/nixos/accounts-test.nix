{ pkgs, inputs }:
let
  existingActivation = pkgs.writeTextFile {
    name = "existing-home-manager-generation";
    destination = "/activate";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu
      if [ ! -e "$HOME/activation-failed-once" ]; then
        touch "$HOME/activation-failed-once"
        exit 1
      fi
      touch "$HOME/existing-generation-activated"
    '';
  };
  bootstrapActivation = pkgs.writeTextFile {
    name = "bootstrap-home-manager-generation";
    destination = "/activate";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      touch "$HOME/bootstrap-generation-invoked"
      exit 1
    '';
  };
in
pkgs.testers.runNixOSTest {
  name = "homed-accounts";
  node.specialArgs = { inherit inputs; };
  nodes = {
    fresh = { lib, ... }: {
      imports = [ ./accounts.nix ./persistence.nix ./home-manager-first-login.nix ];
      _module.args.homeActivationPackage = bootstrapActivation;
      dotfiles.accounts.users.lukecarrier = {
        uid = 1000;
        description = "Luke Carrier";
        initialPassword = "nixos";
        extraGroups = [ "wheel" ];
        authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJdSgkw5KbsBb2bE658DYljtOSYXd5PWYShAqvQfVupW original" ];
      };
      services.openssh.enable = true;
      specialisation.updated.configuration.dotfiles.accounts.users.lukecarrier = {
        description = lib.mkForce "Updated account";
        extraGroups = lib.mkForce [ "wheel" "users" ];
        authorizedKeys = lib.mkForce [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJnEY8uRHXNidhl/e5+WMDKMDbA551pOE3DN9xWg4NH0 rotated" ];
      };
    };
    migration = { lib, ... }: {
      users.users.lukecarrier = {
        isNormalUser = true;
        uid = 1000;
        initialPassword = "old-password";
        extraGroups = [ "wheel" ];
      };
      users.users.legacy-service = { isSystemUser = true; group = "legacy-service"; };
      users.groups.legacy-service = { };
      specialisation.homed.configuration = {
        imports = [ ./accounts.nix ./persistence.nix ];
        users.users.lukecarrier.enable = lib.mkForce false;
        dotfiles.accounts.users.lukecarrier = {
          uid = 1000;
          description = "Luke Carrier";
          initialPassword = "nixos";
          extraGroups = [ "wheel" ];
        };
      };
    };
  };

  testScript = ''
    import json

    start_all()
    fresh.wait_for_unit("homed-accounts.service")
    fresh.succeed("test $(id -u lukecarrier) = 1000")
    fresh.succeed("test $(id -g lukecarrier) = 1000")
    fresh.succeed("userdbctl ssh-authorized-keys lukecarrier | grep original")
    fresh.fail("grep '^lukecarrier:' /etc/passwd")
    fresh.succeed("install -d -o 1000 -g 1000 /home/lukecarrier.homedir/.local/state/nix/profiles")
    fresh.succeed("ln -s ${existingActivation} /home/lukecarrier.homedir/.local/state/nix/profiles/home-manager")
    fresh.succeed("chown -R 1000:1000 /home/lukecarrier.homedir/.local")
    fresh.wait_until_tty_matches("1", "login: ")
    fresh.send_chars("lukecarrier\n")
    fresh.wait_until_tty_matches("1", "Password: ")
    fresh.send_chars("nixos\n")
    fresh.wait_until_succeeds("pgrep -u lukecarrier -t tty1 bash")
    fresh.succeed("test -e /home/lukecarrier/.identity")
    fresh.wait_until_succeeds("test -e /home/lukecarrier/activation-failed-once")
    fresh.fail("test -e /home/lukecarrier/.local/state/home-manager/first-login-activated")
    fresh.fail("test -e /home/lukecarrier/bootstrap-generation-invoked")
    fresh.succeed("systemctl --user --machine=lukecarrier@.host restart home-manager-lukecarrier-first-boot.service")
    fresh.succeed("test -e /home/lukecarrier/existing-generation-activated")
    fresh.succeed("test -e /home/lukecarrier/.local/state/home-manager/first-login-activated")
    fresh.succeed("test $(readlink /home/lukecarrier/.local/state/nix/profiles/home-manager) = ${existingActivation}")
    fresh.send_chars("clear; passwd; echo $? > /tmp/password-change-result\n")
    fresh.wait_until_tty_matches("1", "New password: ")
    fresh.send_chars("a-new-password\n")
    fresh.wait_until_tty_matches("1", "Retype new password: ")
    fresh.send_chars("a-new-password\n")
    fresh.wait_until_tty_matches("1", "Password: ")
    fresh.send_chars("nixos\n")
    fresh.wait_for_file("/tmp/password-change-result")
    fresh.succeed("grep -Fxq 0 /tmp/password-change-result")
    fresh.send_chars("exit\n")
    fresh.wait_until_succeeds("homectl inspect lukecarrier | grep 'State: inactive'")
    fresh.succeed("systemctl restart homed-accounts.service")
    fresh.succeed("PASSWORD=a-new-password homectl activate --no-ask-password lukecarrier")
    fresh.succeed("/run/current-system/specialisation/updated/bin/switch-to-configuration switch")
    fresh.succeed("userdbctl ssh-authorized-keys lukecarrier | grep rotated")
    fresh.fail("userdbctl ssh-authorized-keys lukecarrier | grep original")
    fresh.succeed("id -nG lukecarrier | grep -w users")
    assert json.loads(fresh.succeed("homectl inspect --json=short lukecarrier"))["realName"] == "Updated account"
    fresh.succeed("homectl deactivate lukecarrier")
    fresh.shutdown()
    fresh.start()
    fresh.wait_for_unit("homed-accounts.service")
    fresh.succeed("PASSWORD=a-new-password homectl activate --no-ask-password lukecarrier")

    migration.wait_for_unit("multi-user.target")
    migration.succeed("echo important-data > /home/lukecarrier/keep-me")
    migration.succeed("echo lukecarrier:migration-password | chpasswd")
    migration.succeed("chage -M 99999 -W 14 -I 7 -E 2099-01-01 lukecarrier")
    migration.succeed("install -D -m 0600 /etc/shadow /persist/etc/shadow")
    migration.succeed("sed -i '/^lukecarrier:/d' /etc/shadow")
    legacy_uid = migration.succeed("id -u legacy-service").strip()
    legacy_gid = migration.succeed("getent group legacy-service | cut -d: -f3").strip()
    migration.succeed("systemd-run --unit=legacy-user-process --uid=1000 sleep infinity")
    migration.fail("/run/current-system/specialisation/homed/bin/switch-to-configuration switch")
    migration.succeed("test -f /home/lukecarrier/keep-me")
    migration.succeed("grep '^lukecarrier:' /etc/passwd")
    migration.succeed("test ! -e /var/lib/systemd/home-migration/lukecarrier.json")
    migration.succeed("systemctl stop legacy-user-process.service")
    migration.succeed("cp /persist/etc/shadow /run/original-shadow")
    for password in ("*", "x", "!", ""):
      migration.succeed(f"sed -i 's/^lukecarrier:[^:]*:/lukecarrier:{password}:/' /persist/etc/shadow")
      migration.succeed("systemctl reset-failed homed-accounts.service")
      migration.fail("systemctl restart homed-accounts.service")
      migration.succeed("test -f /home/lukecarrier/keep-me")
      migration.succeed("grep '^lukecarrier:' /etc/passwd")
      migration.succeed("test ! -e /var/lib/systemd/home-migration/lukecarrier.json")
    migration.succeed("rm /persist/etc/shadow")
    migration.succeed("systemctl reset-failed homed-accounts.service")
    migration.fail("systemctl restart homed-accounts.service")
    migration.succeed("test -f /home/lukecarrier/keep-me")
    migration.succeed("test ! -e /var/lib/systemd/home-migration/lukecarrier.json")
    migration.succeed("cp /run/original-shadow /persist/etc/shadow")
    migration.succeed("systemctl reset-failed homed-accounts.service")
    migration.succeed("mkdir /home/lukecarrier/.identity")
    migration.fail("systemctl restart homed-accounts.service")
    migration.succeed("test -e /var/lib/systemd/home-migration/lukecarrier.json")
    migration.succeed("homectl inspect lukecarrier")
    migration.succeed("rmdir /home/lukecarrier.homedir/.identity")
    migration.succeed("systemctl restart homed-accounts.service")
    migration.wait_for_unit("homed-accounts.service")
    migration.fail("grep '^lukecarrier:' /etc/passwd")
    migration.succeed("PASSWORD=migration-password homectl activate --no-ask-password lukecarrier")
    migration.succeed("grep -Fxq important-data /home/lukecarrier/keep-me")
    migration.succeed("test $(id -u lukecarrier) = 1000")
    migration.succeed("id -nG lukecarrier | grep -w wheel")
    record = json.loads(migration.succeed("homectl inspect --json=short lukecarrier"))
    assert record.get("passwordChangeMinUSec", 0) == 0
    assert record["passwordChangeWarnUSec"] == 14 * 86400000000
    assert record["passwordChangeMaxUSec"] == 99999 * 86400000000
    assert record["passwordChangeInactiveUSec"] == 7 * 86400000000
    assert record["notAfterUSec"] == 4070908800000000
    migration.succeed("homectl deactivate lukecarrier")
    migration.succeed("rm /etc/passwd /etc/group /etc/shadow")
    migration.succeed("rm -f /etc/gshadow")
    migration.succeed("systemctl restart systemd-sysusers.service")
    assert migration.succeed("id -u legacy-service").strip() == legacy_uid
    assert migration.succeed("getent group legacy-service | cut -d: -f3").strip() == legacy_gid
    migration.succeed("PASSWORD=migration-password homectl activate --no-ask-password lukecarrier")
  '';
}

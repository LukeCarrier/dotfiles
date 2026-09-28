set shell := ["bash", "-eux", "-o", "pipefail", "-c"]

preserve-generations := "+2"
hostname := `echo $(hostname) | cut -d. -f1 | tr '[:upper:]' '[:lower:]'`
user := `id -un`
os := `uname -s`
op := "switch"
args := "--show-activation-logs --show-trace"
flake := "."

gc:
	nh clean all

home op=op flake=flake user=user hostname=hostname *args=args:
	nh home "{{op}}" "{{flake}}" --configuration "{{user}}@{{hostname}}" {{args}}

host:
	@if [ "{{os}}" = "Darwin" ]; then \
		just host-darwin; \
	else \
		just host-linux; \
	fi

host-android op=op flake=flake *args=args:
	nix-on-droid "{{op}}" --flake "{{flake}}" {{args}}

host-darwin op=op flake=flake hostname=hostname *args=args:
	nh darwin "{{op}}" "{{flake}}" --hostname "{{hostname}}" {{args}}

host-linux op=op flake=flake hostname=hostname *args=args:
	nh os "{{op}}" "{{flake}}" --hostname "{{hostname}}" {{args}}

# Destructively installs a host after provisioning its persistent identities.
host-install config target disk known_hosts installer_key flake=flake:
	known_hosts="$(realpath "{{known_hosts}}")"; \
	test -s "$known_hosts"; \
	installer_key="$(realpath "{{installer_key}}")"; \
	ssh-keygen -y -P '' -f "$installer_key" >/dev/null; \
	ssh_options=(-o "UserKnownHostsFile=\"$known_hosts\"" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes); \
	anywhere_options=(--ssh-option "UserKnownHostsFile=\"$known_hosts\"" --ssh-option GlobalKnownHostsFile=/dev/null --ssh-option StrictHostKeyChecking=yes); \
	read -r -s -p 'Installer root password: ' SSHPASS; printf '\n'; \
	export SSHPASS; \
	facter_report="system/{{config}}/facter.json"; \
	facter_tmp="$(mktemp "$facter_report.XXXXXX")"; \
	trap 'rm -f "$facter_tmp"; unset SSHPASS' EXIT; \
	nixpkgs_owner="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.owner' flake.lock)"; \
	nixpkgs_repo="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.repo' flake.lock)"; \
	nixpkgs_rev="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.rev' flake.lock)"; \
	nixpkgs_ref="github:$nixpkgs_owner/$nixpkgs_repo/$nixpkgs_rev"; \
	sshpass_bin="$(nix build --no-link --print-out-paths "$nixpkgs_ref#sshpass")/bin/sshpass"; \
	nixos_anywhere="$(nix build --no-link --print-out-paths "{{flake}}#nixos-anywhere")/bin/nixos-anywhere"; \
	kexec_image="$(nix build --no-link --print-out-paths "{{flake}}#bootstrap-kexec")/nixos-bootstrap-kexec-x86_64-linux.tar.gz"; \
	"$sshpass_bin" -e ssh "${ssh_options[@]}" "root@{{target}}" test -b "{{disk}}"; \
	"$nixos_anywhere" --env-password -i "$installer_key" "${anywhere_options[@]}" --kexec "$kexec_image" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases kexec; \
	unset SSHPASS; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" 'modprobe zfs && test -d /sys/module/zfs'; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" \
		"nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#nixos-facter' -- -o /tmp/facter.json >/dev/null && cat /tmp/facter.json && rm -f /tmp/facter.json" \
		>"$facter_tmp"; \
	mv "$facter_tmp" "$facter_report"; \
	configured_disk="$(nix eval --raw "{{flake}}#nixosConfigurations.{{config}}.config.disko.devices.disk.disk1.device")"; \
	test "$configured_disk" = "{{disk}}"; \
	"$nixos_anywhere" -i "$installer_key" "${anywhere_options[@]}" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases disko; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" 'active_wifi_uuid="$(nmcli -t -f UUID,TYPE connection show --active | while IFS=: read -r uuid type; do if test "$type" = 802-11-wireless || test "$type" = wifi; then printf "%s\n" "$uuid"; break; fi; done)"; test -n "$active_wifi_uuid"; for connection_dir in /etc/NetworkManager/system-connections /run/NetworkManager/system-connections; do for profile in "$connection_dir"/*; do test -f "$profile" || continue; if grep -q "^uuid=$active_wifi_uuid$" "$profile"; then grep -q "^psk=" "$profile"; install -d -m 700 /mnt/persist/etc/NetworkManager/system-connections; install -m 600 "$profile" "/mnt/persist/etc/NetworkManager/system-connections/$(basename "$profile")"; exit 0; fi; done; done; exit 1'; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" 'umask 077; install -d -m 700 -o 1000 -g 1000 /mnt/home/lukecarrier /mnt/home/lukecarrier/.config /mnt/home/lukecarrier/.config/sops /mnt/home/lukecarrier/.config/sops/age; cat > /mnt/home/lukecarrier/.config/sops/age/keys.txt; chown 1000:1000 /mnt/home/lukecarrier/.config/sops/age/keys.txt; chmod 600 /mnt/home/lukecarrier/.config/sops/age/keys.txt' < .sops/keys; \
	sops --decrypt --extract '["ssh"]["host"]["private"]' secrets/employer-emed.yaml \
		| ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" 'umask 077; install -d -m 700 /mnt/persist/etc/ssh; cat > /mnt/persist/etc/ssh/ssh_host_ed25519_key'; \
	sops --decrypt --extract '["ssh"]["host"]["public"]' secrets/employer-emed.yaml \
		| ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" 'umask 022; cat > /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub'; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" \
		"if test -f /mnt/persist/var/lib/sbctl; then rm /mnt/persist/var/lib/sbctl; fi; install -d -m 700 /mnt/persist/var/lib/sbctl; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock create-keys --export /mnt/persist/var/lib/sbctl/keys --database-path /mnt/persist/var/lib/sbctl/GUID; test -f /mnt/persist/var/lib/sbctl/keys/db/db.pem; install -d -m 700 /mnt/var/lib/sbctl; mountpoint -q /mnt/var/lib/sbctl || mount --bind /mnt/persist/var/lib/sbctl /mnt/var/lib/sbctl; test -f /mnt/var/lib/sbctl/keys/db/db.pem"; \
	"$nixos_anywhere" -i "$installer_key" "${anywhere_options[@]}" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases install; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" \
		"set -e; install -d -m 700 /var/lib/sbctl; mountpoint -q /var/lib/sbctl || mount --bind /mnt/persist/var/lib/sbctl /var/lib/sbctl; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock status; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock enroll-keys --microsoft --ignore-immutable; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock status; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock list-enrolled-keys"; \
	"$nixos_anywhere" -i "$installer_key" "${anywhere_options[@]}" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases reboot

# Resumes a failed install after Disko and identity provisioning completed.
host-install-resume config target known_hosts installer_key flake=flake:
	known_hosts="$(realpath "{{known_hosts}}")"; \
	test -s "$known_hosts"; \
	installer_key="$(realpath "{{installer_key}}")"; \
	ssh-keygen -y -P '' -f "$installer_key" >/dev/null; \
	ssh_options=(-o "UserKnownHostsFile=\"$known_hosts\"" -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=yes); \
	anywhere_options=(--ssh-option "UserKnownHostsFile=\"$known_hosts\"" --ssh-option GlobalKnownHostsFile=/dev/null --ssh-option StrictHostKeyChecking=yes); \
	nixpkgs_owner="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.owner' flake.lock)"; \
	nixpkgs_repo="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.repo' flake.lock)"; \
	nixpkgs_rev="$(jq -r '.nodes[.nodes.root.inputs["nixpkgs-unstable"]].locked.rev' flake.lock)"; \
	nixpkgs_ref="github:$nixpkgs_owner/$nixpkgs_repo/$nixpkgs_rev"; \
	nixos_anywhere="$(nix build --no-link --print-out-paths "{{flake}}#nixos-anywhere")/bin/nixos-anywhere"; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" \
		'test -f /mnt/persist/var/lib/sbctl/keys/db/db.pem; install -d -m 700 /mnt/var/lib/sbctl; mountpoint -q /mnt/var/lib/sbctl || mount --bind /mnt/persist/var/lib/sbctl /mnt/var/lib/sbctl; test -f /mnt/var/lib/sbctl/keys/db/db.pem'; \
	"$nixos_anywhere" -i "$installer_key" "${anywhere_options[@]}" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases install; \
	ssh -i "$installer_key" -o IdentitiesOnly=yes "${ssh_options[@]}" "root@{{target}}" \
		"set -e; install -d -m 700 /var/lib/sbctl; mountpoint -q /var/lib/sbctl || mount --bind /mnt/persist/var/lib/sbctl /var/lib/sbctl; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock status; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock enroll-keys --microsoft --ignore-immutable; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock status; nix --extra-experimental-features 'nix-command flakes' run '$nixpkgs_ref#sbctl' -- --disable-landlock list-enrolled-keys"; \
	"$nixos_anywhere" -i "$installer_key" "${anywhere_options[@]}" --flake "{{flake}}#{{config}}" --target-host "root@{{target}}" --phases reboot

# Destructively formats disposable VM disks and installs the selected NixOS system.
# Disko supplies a dummy credential inside this isolated harness.
host-vm-test hostname=hostname flake=flake *args:
	nix build "{{flake}}#bootstrap-kexec-network-test" --print-build-logs {{args}}
	nix build "{{flake}}#nixosConfigurations.{{hostname}}.config.system.build.installTest" --print-build-logs {{args}}

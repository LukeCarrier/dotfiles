.PHONY: gc gc-aggressive home host host-android host-darwin

PRESERVE_GENERATIONS := +2

gc:
	nix-collect-garbage --delete-old

gc-aggressive:
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations $(PRESERVE_GENERATIONS)

home:
	nix run home-manager/release-24.05 -- switch --flake ".#$(USER)@$(shell hostname)"

host:
	sudo nixos-rebuild switch --upgrade --flake ".#$(shell hostname)"

host-android:
	nix-on-droid switch --flake .

host-darwin:
	nix run nix-darwin -- switch --flake .

.PHONY: gc gc-aggressive home host host-android host-darwin

PRESERVE_GENERATIONS := +2

gc:
	nix-collect-garbage --delete-old

gc-aggressive:
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations $(PRESERVE_GENERATIONS)

home:
	nix run home-manager -- switch -b hmbak --flake ".#$(USER)@$(shell hostname)" --show-trace

host:
	sudo nixos-rebuild switch --upgrade --flake ".#$(shell hostname)" --show-trace

host-android:
	nix-on-droid switch --flake . --show-trace

host-darwin:
	sudo nix run nix-darwin -- switch --flake . --show-trace

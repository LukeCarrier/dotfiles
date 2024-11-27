.PHONY: gc home host host-android

gc:
	nix-collect-garbage --delete-old

home:
	nix run home-manager/release-24.05 -- switch --flake ".#$(USER)@$(shell hostname)"

host:
	sudo nixos-rebuild switch --upgrade --flake ".#$(shell hostname)"

host-android:
	nix-on-droid switch --flake .

host-darwin:
	nix run nix-darwin -- switch --flake .

.PHONY: home host

home:
	nix run home-manager/release-24.05 -- switch --flake ".#$(USER)@$(shell hostname)"

host:
	sudo nixos-rebuild switch --upgrade --flake ".#$(shell hostname)"
.PHONY: gc gc-aggressive home home-darwin host host-android host-darwin

PRESERVE_GENERATIONS := +2
HOSTNAME := $(shell echo $(shell hostname) | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
USER := $(shell id -un)
FLAKE := .

gc:
	nix-collect-garbage --delete-old

gc-aggressive:
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations $(PRESERVE_GENERATIONS)

home:
	nix run home-manager -- switch -b hmbak --flake "$(FLAKE)#$(USER)@$(HOSTNAME)" --show-trace

home-darwin: home
	@tail -n 20 $HOME/Library/Logs/SopsNix/stderr 2>/dev/null || true
	@tail -n 20 $HOME/Library/Logs/SopsNix/stdout 2>/dev/null || true

host:
	sudo nixos-rebuild switch --upgrade --flake "$(FLAKE)#$(HOSTNAME)" --show-trace

host-android:
	nix-on-droid switch --flake $(FLAKE) --show-trace

host-darwin:
	sudo nix run nix-darwin -- switch --flake "$(FLAKE)#$(HOSTNAME)" --show-trace

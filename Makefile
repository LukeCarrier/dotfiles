.PHONY: gc gc-aggressive home home-darwin host host-android host-darwin

PRESERVE_GENERATIONS := +2
HOSTNAME := $(shell echo $(shell hostname) | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
USER := $(shell id -un)
FLAKE := .

gc:
	nh clean all

home:
	nh home switch "$(FLAKE)" --configuration "$(USER)@$(HOSTNAME)"

host:
	nh os switch "$(FLAKE)" --hostname "$(HOSTNAME)"

host-android:
	nix-on-droid switch --flake "$(FLAKE)" --show-trace

host-darwin:
	nh darwin switch --hostname "$(HOSTNAME)"

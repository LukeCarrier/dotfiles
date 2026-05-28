.PHONY: gc gc-aggressive home home-darwin host host-android host-darwin

PRESERVE_GENERATIONS := +2
HOSTNAME := $(shell echo $(shell hostname) | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
USER := $(shell id -un)
OP := switch
ARGS := --show-trace
FLAKE := .

gc:
	nh clean all

home:
	nh home "$(OP)" "$(FLAKE)" --configuration "$(USER)@$(HOSTNAME)" $(ARGS)

host:
	nh os "$(OP)" "$(FLAKE)" --hostname "$(HOSTNAME)" $(ARGS)

host-android:
	nix-on-droid "$(OP)" --flake "$(FLAKE)" $(ARGS)

host-darwin:
	nh darwin "$(OP)" "$(FLAKE)" --hostname "$(HOSTNAME)" $(ARGS)

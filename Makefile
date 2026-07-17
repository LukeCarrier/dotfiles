.PHONY: gc gc-aggressive home home-darwin host host-android host-darwin host-linux

PRESERVE_GENERATIONS := +2
HOSTNAME := $(shell echo $(shell hostname) | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
USER := $(shell id -un)
OS := $(shell uname -s)
OP := switch
ARGS := --show-trace
FLAKE := .

gc:
	nh clean all

home:
	nh home "$(OP)" "$(FLAKE)" --configuration "$(USER)@$(HOSTNAME)" $(ARGS)

host:
ifeq ($(OS),Darwin)
	$(MAKE) host-darwin
else
	$(MAKE) host-linux
endif

host-android:
	nix-on-droid "$(OP)" --flake "$(FLAKE)" $(ARGS)

host-darwin:
	nh darwin "$(OP)" "$(FLAKE)" --hostname "$(HOSTNAME)" $(ARGS)

host-linux:
	nh os "$(OP)" "$(FLAKE)" --hostname "$(HOSTNAME)" $(ARGS)

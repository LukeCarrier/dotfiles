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

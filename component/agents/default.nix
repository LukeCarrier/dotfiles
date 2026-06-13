{ lib, ... }:
# Wires up the agents subsystem: the `agents.commands` and `agents.definitions`
# option declarations (from lib/agents.nix) plus the command and agent
# definitions that populate them. Import this from any component that lowers
# either `agents.commands` or `agents.definitions`.
{
  imports = [
    (import ../../lib/agents.nix { inherit lib; }).commandsModule
    (import ../../lib/agents.nix { inherit lib; }).definitionsModule
    ./adr.nix
    ./agents.nix
  ];
}

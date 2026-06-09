{ lib, ... }:
# Wires up the agents subsystem: the `agents.commands` option declaration
# (from lib/agents.nix) plus the command definitions that populate it. Import
# this from any component that lowers `agents.commands`.
{
  imports = [
    (import ../../lib/agents.nix { inherit lib; }).commandsModule
    ./adr.nix
  ];
}

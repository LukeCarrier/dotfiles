{ lib }:
# Shared library for the agents subsystem. It bundles the two pieces of
# tool-agnostic plumbing that both component/goose and component/opencode lower
# into their own on-disk formats:
#
#   * `substitute` — resolves @SOPS_PLACEHOLDER@ references inside the shared
#     programs.mcp.servers shape.
#   * `commandsModule` — declares the `agents.commands` option: a tool-agnostic
#     description of agent slash commands / recipes. The definitions themselves
#     are supplied as config (see component/agents/adr.nix); nothing here is
#     specific to any particular command set.
{
  substitute =
    config: lib: text:
    let
      refs = builtins.match "(@[^@]+@)" text;
    in
    if refs == null then
      text
    else
      let
        keys = map (p: lib.removePrefix "@" (lib.removeSuffix "@" p)) refs;
        replacements = map (key: config.sops.placeholder.${key}) keys;
      in
      builtins.replaceStrings refs replacements text;

  commandsModule =
    { lib, ... }:
    let
      inherit (lib) mkOption types;

      parameterType = types.submodule {
        options = {
          key = mkOption {
            type = types.str;
            description = "Parameter name, referenced from the command body.";
          };
          input_type = mkOption {
            type = types.str;
            default = "string";
            description = "Parameter value type.";
          };
          requirement = mkOption {
            type = types.str;
            default = "required";
            description = "Whether the parameter is required or optional.";
          };
          description = mkOption {
            type = types.str;
            description = "Human-readable parameter description.";
          };
        };
      };

      commandType = types.submodule {
        options = {
          title = mkOption {
            type = types.str;
            description = "Human-readable command title.";
          };
          description = mkOption {
            type = types.str;
            description = "One-line summary of what the command does.";
          };
          prompt = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Recipe prompt; falls back to `description` when null.";
          };
          body = mkOption {
            type = types.lines;
            description = "Shared instruction body, in Markdown.";
          };
          maxTurns = mkOption {
            type = types.ints.positive;
            default = 50;
            description = "Maximum agent turns permitted for the command.";
          };
          timeout = mkOption {
            type = types.ints.positive;
            default = 300;
            description = "Extension/tool timeout in seconds.";
          };
          agent = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Agent to route the command to; null leaves it unset.";
          };
          parameters = mkOption {
            type = types.listOf parameterType;
            default = [ ];
            description = "Ordered list of command parameters.";
          };
        };
      };
    in
    {
      options.agents.commands = mkOption {
        type = types.attrsOf commandType;
        default = { };
        description = ''
          Agent commands, keyed by name. Every command is lowered into the
          native format of each agent (Goose recipes, opencode commands, Claude
          Code commands) by its respective component.
        '';
      };
    };
}

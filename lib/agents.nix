{ lib }:
# Shared library for the agents subsystem. It bundles the three pieces of
# tool-agnostic plumbing that each component lowers into its own on-disk format:
#
#   * `substitute` — resolves @SOPS_PLACEHOLDER@ references inside the shared
#     programs.mcp.servers shape.
#   * `commandsModule` — declares the `agents.commands` option: a tool-agnostic
#     description of agent slash commands / recipes. The definitions themselves
#     are supplied as config (see component/agents/adr.nix).
#   * `definitionsModule` — declares the `agents.definitions` option: a
#     tool-agnostic description of agent roles (system prompts, mode, etc.).
#     The definitions themselves are supplied as config (see
#     component/agents/agents.nix).
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
          fixtures = mkOption {
            type = types.attrsOf types.path;
            default = { };
            description = "Fixture files required by this command, keyed by filename.";
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

  definitionsModule =
    { lib, ... }:
    let
      inherit (lib) mkOption types;

      permissionValueType = types.oneOf [
        (types.enum [
          "allow"
          "deny"
          "ask"
        ])
        (types.attrsOf (types.enum [
          "allow"
          "deny"
          "ask"
        ]))
      ];
    in
    {
      options.agents.definitions = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            description = mkOption {
              type = types.str;
              description = "Agent role description.";
            };
            mode = mkOption {
              type = types.enum [
                "primary"
                "subagent"
              ];
              description = "Whether the agent runs independently or as a subagent.";
            };
            temperature = mkOption {
              type = types.float;
              default = 0.1;
              description = "LLM temperature for the agent.";
            };
            model = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Model override (tool-specific resolution).";
            };
            body = mkOption {
              type = types.lines;
              description = "System prompt / agent instructions.";
            };
            tools = mkOption {
              type = types.attrsOf types.bool;
              default = {
                "*" = true;
              };
              description = "Tool availability (opencode).";
            };
            permission = mkOption {
              type = types.attrsOf permissionValueType;
              default = { };
              description = "Permission rules (opencode).";
            };
          };
        });
        default = { };
        description = "Agent role definitions, keyed by name.";
      };

      options.agents.skills = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            source = mkOption {
              type = types.path;
              description = "Path to the SKILL.md file.";
            };
            fixtures = mkOption {
              type = types.attrsOf types.path;
              default = { };
              description = "Fixture files required by this skill, keyed by filename.";
            };
          };
        });
        default = { };
        description = "Skills available to agents, keyed by skill name.";
      };
    };
}

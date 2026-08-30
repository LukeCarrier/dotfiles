{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };

  buildSkillFiles = basePath:
    builtins.foldl' (acc: name:
      let
        skill = config.agents.skills.${name};
        prefix = "${basePath}/${name}";
      in
      acc
      // { "${prefix}/SKILL.md".source = skill.source; }
      // lib.mapAttrs' (fname: fpath:
        lib.nameValuePair "${prefix}/${fname}" { source = fpath; }
      ) skill.fixtures
    ) { } (builtins.attrNames config.agents.skills);

  buildCommandFixtures = commandsBase:
    builtins.foldl' (acc: cmd:
      acc // lib.mapAttrs' (fname: fpath:
        lib.nameValuePair "${commandsBase}/${fname}" { source = fpath; }
      ) (cmd.fixtures or { })
    ) { } (builtins.attrValues config.agents.commands);

  piProviders = lib.mapAttrs (
    _provId: prov:
    if prov.type == "openai" then
      {
        baseUrl = prov.baseUrl;
        api = "openai-completions";
        apiKey = "not-needed";
        models = lib.mapAttrsToList (modelId: m: {
          id = modelId;
        }
        // lib.optionalAttrs (m.name != null) { name = m.name; }
        // lib.optionalAttrs (m.contextLimit != null) {
          contextWindow = m.contextLimit;
          maxTokens = 32000;
        }) prov.models;
      }
    else
      { }
  ) config.agents.providers;

  piModelsJson = pkgs.writeText "models.json" (builtins.toJSON { providers = piProviders; });
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = with pkgs; [ pi-coding-agent ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../agents/AGENTS.md;
    ".pi/agent/models.json".source = piModelsJson;
  }
  // buildSkillFiles ".pi/agent/skills"
  // buildCommandFixtures ".pi/agent/commands";
}

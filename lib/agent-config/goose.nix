{
  pkgs,
  config,
  lib,
  agentsLib,
}:
let
  substitute = agentsLib.substitute config lib;

  buildSkillFiles =
    basePath:
    builtins.foldl' (
      acc: name:
      let
        skill = config.agents.skills.${name};
        prefix = "${basePath}/${name}";
      in
      acc
      // {
        "${prefix}/SKILL.md" = skill.source;
      }
      // lib.mapAttrs' (fname: fpath: lib.nameValuePair "${prefix}/${fname}" fpath) skill.fixtures
    ) { } (builtins.attrNames config.agents.skills);

  buildCommandFixtures =
    commandsBase:
    builtins.foldl' (
      acc: cmd: acc // lib.mapAttrs' (fname: fpath: lib.nameValuePair "${commandsBase}/${fname}" fpath) (cmd.fixtures or { })
    ) { } (builtins.attrValues config.agents.commands);

  buildGooseMcpConfig =
    name: serverDef:
    let
      url = serverDef.url or null;
      command = serverDef.command or null;
      isRemote = url != null;
      envs = lib.mapAttrs (_: v: substitute (toString v)) (serverDef.env or { });
      base =
        {
          inherit name;
          enabled = serverDef.enabled or false;
          timeout = 300;
          bundled = false;
        }
        // lib.optionalAttrs (envs != { }) { inherit envs; };
    in
    if isRemote then
      base
      // {
        type = "streamable_http";
        uri = substitute url;
      }
    else
      base
      // {
        type = "stdio";
        cmd = substitute (toString command);
        args = map (a: substitute (toString a)) (serverDef.args or [ ]);
      };

  gooseMcpServers = lib.mapAttrs buildGooseMcpConfig config.programs.mcp.servers;

  buildGooseRecipe =
    cmd:
    builtins.toJSON (
      {
        version = "1.0.0";
        title = cmd.title;
        description = cmd.description;
        settings.max_turns = cmd.maxTurns;
        instructions = cmd.body;
        prompt = if cmd.prompt == null then cmd.description else cmd.prompt;
        extensions = [
          {
            type = "builtin";
            name = "developer";
            timeout = cmd.timeout;
            bundled = true;
          }
        ];
      }
      // lib.optionalAttrs (cmd.parameters != [ ]) { parameters = cmd.parameters; }
    );

  recipePath = name: "${lib.replaceStrings [ "." ] [ "/" ] name}.yaml";

  recipeFiles = lib.mapAttrs (
    name: cmd: pkgs.writeText "${name}.yaml" (buildGooseRecipe cmd)
  ) config.agents.commands;

  replaceRecipePaths =
    content:
    let
      names = lib.attrNames config.agents.commands;
    in
    lib.strings.replaceStrings (map recipePath names) (map (name: "${recipeFiles.${name}}") names) content;

  adrYaml = pkgs.writeTextFile {
    name = "adr.yaml";
    text = replaceRecipePaths (builtins.readFile ../../component/goose/recipes/adr.yaml);
  };

  buildGooseAgentRecipe =
    name: agent:
    builtins.toJSON {
      version = "1.0.0";
      title = name;
      description = agent.description;
      prompt = agent.body;
      extensions = [
        {
          type = "builtin";
          name = "developer";
          timeout = 300;
          bundled = true;
        }
      ];
    };

  agentRecipeFiles = lib.mapAttrs' (
    name: agent:
    lib.nameValuePair "recipes/${name}.yaml" (pkgs.writeText "${name}.yaml" (buildGooseAgentRecipe name agent))
  ) config.agents.definitions;

  recipePathFiles = lib.mapAttrs' (
    name: file: lib.nameValuePair "recipes/${recipePath name}" file
  ) recipeFiles;

  baseConfig = {
    extensions = gooseMcpServers;
  };

  skillFiles = buildSkillFiles "skills";

  fixtureFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair "recipes/${name}" path
  ) (buildCommandFixtures "");

  gooseConfigFiles =
    {
      "config.yaml" = pkgs.writeText "config.yaml" (builtins.toJSON baseConfig);
      "adversary.md" = ../../component/goose/adversary.md;
      "custom_providers/custom_peacehaven_llama-swap_anthropic.json" = ../../component/goose/custom_providers/custom_peacehaven_llama-swap_anthropic.json;
      "custom_providers/custom_peacehaven_llama-swap_openai.json" = ../../component/goose/custom_providers/custom_peacehaven_llama-swap_openai.json;
      "recipes/adr.yaml" = adrYaml;
      "recipes/adr/housekeeping.sh" = ../../component/agents/adr/housekeeping.sh;
    }
    // agentRecipeFiles
    // recipePathFiles
    // fixtureFiles;
  
  agentsConfigFiles = skillFiles;

  configDrv = pkgs.runCommand "goose-config" { } ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (relPath: srcPath: ''
        mkdir -p $out/$(dirname "${relPath}")
        ${
          if lib.isDerivation srcPath || lib.isStorePath srcPath then
            "ln -s ${srcPath} $out/${relPath}"
          else
            "cp -r ${srcPath} $out/${relPath}"
        }
      '') gooseConfigFiles
    )}
  '';

  agentsDrv = pkgs.runCommand "goose-agents" { } ''
    mkdir -p $out
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (relPath: srcPath: ''
        mkdir -p $out/$(dirname "${relPath}")
        ${
          if lib.isDerivation srcPath || lib.isStorePath srcPath then
            "ln -s ${srcPath} $out/${relPath}"
          else
            "cp -r ${srcPath} $out/${relPath}"
        }
      '') agentsConfigFiles
    )}
  '';
in
{
  config = configDrv;
  agents = agentsDrv;
}

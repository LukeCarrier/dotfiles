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

  buildMcpConfig =
    _: mcpDef:
    let
      url = mcpDef.url or null;
      command = mcpDef.command or null;
      mcpType = if url != null then "remote" else "local";
      enabled = mcpDef.enabled or false;
      baseMcp = {
        type = mcpType;
        enabled = if enabled == null then false else enabled;
      };
      mcpWithUrl = if url != null then baseMcp // { inherit url; } else baseMcp;
      mcpWithCommand =
        if command != null then
          mcpWithUrl // { command = map substitute ([ command ] ++ (mcpDef.args or [ ])); }
        else
          mcpWithUrl;
      mcpWithEnv =
        if (mcpDef.env or { }) != { } then
          mcpWithCommand // { environment = lib.mapAttrs (_: substitute) mcpDef.env; }
        else
          mcpWithCommand;
    in
    mcpWithEnv;

  mcpConfigurations = lib.mapAttrs buildMcpConfig config.programs.mcp.servers;

  buildOpencodeCommand =
    cmd:
    let
      frontmatter =
        [
          "description: ${cmd.description}"
        ]
        ++ lib.optional (cmd.agent != null) "agent: ${cmd.agent}"
        ++ [ "subtask: false" ];
    in
    ''
      ---
      ${lib.concatStringsSep "\n" frontmatter}
      ---

    '' + cmd.body;

  commandFiles = lib.mapAttrs' (
    name: cmd:
    lib.nameValuePair "commands/${name}.md" (pkgs.writeText "${name}.md" (buildOpencodeCommand cmd))
  ) config.agents.commands;

  buildOpencodeAgent =
    name: agent:
    let
      isSafeKey = k: builtins.match "[a-zA-Z_][a-zA-Z0-9_-]*" k != null;
      quoteIfNeeded = k: if isSafeKey k then k else ''"${k}"'';
      safeVal = v: if v then "true" else "false";

      toolsLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "  ${quoteIfNeeded k}: ${safeVal v}") agent.tools);

      renderPermission =
        indent: attrs:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            k: v:
            if builtins.isAttrs v then
              "${indent}${quoteIfNeeded k}:\n${renderPermission "${indent}  " v}"
            else
              "${indent}${quoteIfNeeded k}: ${v}"
          ) attrs
        );
    in
    ''
      ---
      description: ${agent.description}
      mode: ${agent.mode}
      temperature: ${builtins.toString agent.temperature}
    ''
    + lib.optionalString (agent.model != null) "model: ${agent.model}\n"
    + ''
      tools:
      ${toolsLines}
      permission:
      ${renderPermission "  " agent.permission}
      ---

    ''
    + agent.body;

  agentFiles = lib.mapAttrs' (
    name: agent:
    lib.nameValuePair "agent/${name}.md" (pkgs.writeText "${name}.md" (buildOpencodeAgent name agent))
  ) config.agents.definitions;

  baseConfig = builtins.fromJSON (builtins.readFile ../../component/opencode/opencode.json);
  fullConfig = lib.recursiveUpdate baseConfig { mcp = mcpConfigurations; };

  skillFiles = buildSkillFiles "skills";
  fixtureFiles = buildCommandFixtures "commands";

  configFiles =
    {
      "opencode.jsonc" = pkgs.writeText "opencode.jsonc" (builtins.toJSON fullConfig);
      "AGENTS.md" = ../../component/agents/AGENTS.md;
      "antigravity.json" = ../../component/opencode/antigravity.json;
    }
    // commandFiles
    // agentFiles
    // skillFiles
    // fixtureFiles;
in
pkgs.runCommand "opencode-config" { } ''
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
    '') configFiles
  )}
''

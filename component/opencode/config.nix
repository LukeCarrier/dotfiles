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
        fixturesDir =
          if name == "toon" then
            "${config.home.homeDirectory}/.config/opencode/commands"
          else
            "${config.home.homeDirectory}/.config/opencode/skills/${name}";
        rawContent = builtins.readFile skill.source;
        substituted = lib.replaceStrings [ "\${FIXTURES_DIR}" ] [ fixturesDir ] rawContent;
      in
      acc
      // {
        "${prefix}/SKILL.md" = pkgs.writeText "SKILL.md" substituted;
      }
      // lib.mapAttrs' (fname: fpath: lib.nameValuePair "${prefix}/${fname}" fpath) skill.fixtures
    ) { } (builtins.attrNames config.agents.skills);

  buildCommandFixtures =
    commandsBase:
    builtins.foldl' (
      acc: cmd: acc // lib.mapAttrs' (fname: fpath: lib.nameValuePair "${commandsBase}/${fname}" fpath) (cmd.fixtures or { })
    ) { } (builtins.attrValues config.agents.commands);

  # Opencode's schema is a discriminated union on `type: "local" | "remote"`
  # (not the generic "stdio"/"http" from lib.hm.mcp.addType) and requires
  # `enabled` to always be present, so it needs its own transform rather than
  # the generic one.
  toOpencodeShape =
    server:
    let
      isRemote = server ? url && server.url != null;
    in
    server
    // {
      type = if isRemote then "remote" else "local";
      enabled = if (server.enabled or null) == null then false else server.enabled;
    }
    // lib.optionalAttrs (!isRemote && (server.command or null) != null) {
      command = [ server.command ] ++ (server.args or [ ]);
    };

  buildMcpConfig =
    name: mcpDef:
    lib.hm.mcp.transformMcpServer {
      server = mcpDef;
      extraTransforms = [ toOpencodeShape ];
      # Opencode understands {file:...} natively; use it for file-ref env vars.
      mkFileRef = path: "{file:${path}}";
      # Opencode uses `command` as a list (command + args combined).
      exclude = [ "args" ];
    };

  mcpConfigurations = lib.mapAttrs buildMcpConfig config.programs.mcp.servers;

  buildOpencodeCommand =
    cmd:
    let
      fixturesDir = "${config.home.homeDirectory}/.config/opencode/commands";
      body' = lib.replaceStrings [ "\${FIXTURES_DIR}" ] [ fixturesDir ] cmd.body;
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

    '' + body';

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
      fixturesDir = "${config.home.homeDirectory}/.config/opencode/commands";
      body' = lib.replaceStrings [ "\${FIXTURES_DIR}" ] [ fixturesDir ] agent.body;
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
    + body';

  agentFiles = lib.mapAttrs' (
    name: agent:
    lib.nameValuePair "agent/${name}.md" (pkgs.writeText "${name}.md" (buildOpencodeAgent name agent))
  ) config.agents.definitions;

  opencodeProviders = lib.mapAttrs (
    provId: prov:
    if prov.type == "openai" then
      {
        npm = "@ai-sdk/openai-compatible";
        name = prov.name;
        options.baseURL = prov.baseUrl;
        models = lib.mapAttrs (
          modelId: m:
          {
            name = if m.name != null then m.name else modelId;
          }
          // lib.optionalAttrs (m.contextLimit != null) {
            limit = {
              context = m.contextLimit;
              output = 32000;
            };
          }
        ) prov.models;
      }
    else
      { }
  ) config.agents.providers;

  baseConfig = builtins.fromJSON (builtins.readFile ./opencode.json);
  fullConfig = lib.recursiveUpdate baseConfig {
    mcp = mcpConfigurations;
    provider = opencodeProviders;
  };

  skillFiles = buildSkillFiles "skills";
  fixtureFiles = buildCommandFixtures "commands";

  configFiles =
    {
      "opencode.jsonc" = pkgs.writeText "opencode.jsonc" (builtins.toJSON fullConfig);
      "tui.json" = ./tui.json;
      "AGENTS.md" = ../agents/AGENTS.md;
      "antigravity.json" = ./antigravity.json;
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

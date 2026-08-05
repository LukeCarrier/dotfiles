{
  pkgs,
  config,
  lib,
  agentsLib,
}:
let
  substitute = agentsLib.substitute config lib;

  buildCodexPrompt =
    cmd:
    let
      argumentHint = lib.concatMapStringsSep " " (p: "[${p.key}]") cmd.parameters;
      frontmatter =
        [
          "description: ${cmd.description}"
        ]
        ++ lib.optional (cmd.parameters != [ ]) "argument-hint: ${argumentHint}";
    in
    ''
      ---
      ${lib.concatStringsSep "\n" frontmatter}
      ---

    '' + cmd.body;

  promptFiles = lib.mapAttrs' (
    name: cmd:
    lib.nameValuePair "prompts/${name}.md" (pkgs.writeText "${name}.md" (buildCodexPrompt cmd))
  ) config.agents.commands;

  buildCodexAgent =
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
    lib.nameValuePair "prompts/${name}.md" (pkgs.writeText "${name}.md" (buildCodexAgent name agent))
  ) config.agents.definitions;

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

  skillFiles = buildSkillFiles "skills";
  fixtureFiles = buildCommandFixtures "prompts";

  configFiles =
    {
      "AGENTS.md" = ../../component/agents/AGENTS.md;
      "prompts/adr.housekeeping.sh" = ../../component/agents/adr/housekeeping.sh;
    }
    // promptFiles
    // agentFiles
    // skillFiles
    // fixtureFiles;
in
pkgs.runCommand "codex-config" { } ''
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

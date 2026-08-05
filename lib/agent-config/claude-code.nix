{
  pkgs,
  config,
  lib,
  agentsLib,
}:
let
  substitute = agentsLib.substitute config lib;

  commandPath = name: "${lib.replaceStrings [ "." ] [ "/" ] name}.md";

  buildClaudeCommand =
    cmd:
    let
      argumentHint = lib.concatMapStringsSep " " (p: "[${p.key}]") cmd.parameters;
      frontmatter =
        [
          "description: ${cmd.description}"
        ]
        ++ lib.optional (cmd.parameters != [ ]) "argument-hint: ${argumentHint}"
        ++ [ "allowed-tools: Bash(date:*)" ];
    in
    ''
      ---
      ${lib.concatStringsSep "\n" frontmatter}
      ---

    '' + cmd.body;

  commandFiles = lib.mapAttrs' (
    name: cmd:
    lib.nameValuePair "commands/${commandPath name}" (pkgs.writeText "${name}.md" (buildClaudeCommand cmd))
  ) config.agents.commands;

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
  fixtureFiles = buildCommandFixtures "commands";

  configFiles =
    {
      "commands/adr/housekeeping.sh" = ../../component/agents/adr/housekeeping.sh;
    }
    // commandFiles
    // skillFiles
    // fixtureFiles;
in
pkgs.runCommand "claude-code-config" { } ''
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

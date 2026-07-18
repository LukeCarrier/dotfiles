{
  config,
  pkgs,
  lib,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  buildSkillFiles = basePath:
    lib.mapAttrs' (name: path:
      lib.nameValuePair "${basePath}/${name}/SKILL.md" { source = path; }
    ) config.agents.skills;
  substitute = agentsLib.substitute config lib;

  # programs.mcp.servers is home-manager's free-form jsonFormat.type option,
  # so we piggy-back on it as a shared source for our own generators and
  # slip in an `enabled` field HM itself doesn't define. Default to false
  # to avoid overloading agents with permissions and tool descriptions.
  buildMcpConfig =
    _: mcpDef:
    let
      url = mcpDef.url or null;
      command = mcpDef.command or null;
      mcpType = if url != null then "remote" else "local";
      baseMcp = {
        type = mcpType;
        enabled = mcpDef.enabled or false;
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

  # Lower a tool-agnostic command definition (config.agents.commands) into an
  # opencode command: YAML frontmatter followed by the shared body.
  buildOpencodeCommand =
    cmd:
    let
      frontmatter = [
        "description: ${cmd.description}"
      ]
      ++ lib.optional (cmd.agent != null) "agent: ${cmd.agent}"
      ++ [ "subtask: false" ];
    in
    ''
      ---
      ${lib.concatStringsSep "\n" frontmatter}
      ---

    ''
    + cmd.body;

  commandFiles = lib.mapAttrs' (
    name: cmd:
    lib.nameValuePair ".config/opencode/commands/${name}.md" {
      source = pkgs.writeText "${name}.md" (buildOpencodeCommand cmd);
    }
  ) config.agents.commands;

  # Lower a tool-agnostic agent definition (config.agents.definitions) into an
  # opencode agent file: YAML frontmatter followed by the shared body.
  buildOpencodeAgent =
    name: agent:
    pkgs.writeText "agent-${name}.md" (
      let
        isSafeKey = k: builtins.match "[a-zA-Z_][a-zA-Z0-9_-]*" k != null;
        quoteIfNeeded = k: if isSafeKey k then k else ''"${k}"'';
        safeVal = v: if v then "true" else "false";

        toolsLines = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: "  ${quoteIfNeeded k}: ${safeVal v}") agent.tools
        );

        renderPermission = indent: attrs:
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (k: v:
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
      + agent.body
    );

  agentFiles = lib.mapAttrs' (
    name: agent:
    lib.nameValuePair ".config/opencode/agent/${name}.md" {
      source = buildOpencodeAgent name agent;
    }
  ) config.agents.definitions;

  userFacingPkgs = with pkgs; [ mcp-remote ];
  wrapperPkgs = with pkgs; [
    emcee
    github-mcp-server
    terraform-mcp-server
  ];
  opencode = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [ pkgs.opencode ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${pkgs.lib.makeBinPath wrapperPkgs}
    '';
  };
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = [
    opencode
    pkgs.opencode-desktop
  ]
  ++ userFacingPkgs;

  sops = {
    # MCP servers carry secrets, so they're rendered to a staging file and
    # overlaid last at activation (keeping nix store paths fresh). The static
    # base config (./opencode.json, no secrets) is referenced directly.
    templates."opencode-mcp.json" = {
      content = builtins.toJSON { mcp = mcpConfigurations; };
      path = "${config.home.homeDirectory}/.config/opencode/.opencode.jsonc.mcp";
    };
  };

  # Deep-merge our managed config into opencode's mutable opencode.jsonc with
  # jq's `*`: base then existing (so manual edits win) then the MCP subtree (so
  # MCP stays declarative via programs.mcp.servers and its store paths fresh).
  # The existing file must be plain JSON; if it doesn't parse it's reseeded.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    mcp="${config.home.homeDirectory}/.config/opencode/.opencode.jsonc.mcp"
    target="$HOME/.config/opencode/opencode.jsonc"
    if [ -r "$mcp" ]; then
      tmp="$(mktemp)"
      ${pkgs.python3}/bin/python3 - ${./opencode.json} "$target" "$mcp" "$tmp" << 'EOF'
import json, sys

def deep_merge(base, override):
    result = dict(base)
    for k, v in override.items():
        if v is None:
            pass
        elif k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        else:
            result[k] = v
    return result

base_path, target_path, mcp_path, out_path = sys.argv[1:]

with open(base_path) as f:
    merged = json.load(f)
try:
    with open(target_path) as f:
        merged = deep_merge(merged, json.load(f))
except (FileNotFoundError, json.JSONDecodeError):
    pass
with open(mcp_path) as f:
    merged = deep_merge(merged, json.load(f))

with open(out_path, 'w') as f:
    json.dump(merged, f, indent=2)
EOF
      $DRY_RUN_CMD mv "$tmp" "$target"
    fi
  '';

  home.file = {
    ".config/opencode/AGENTS.md".source = ../agents/AGENTS.md;
    ".config/opencode/antigravity.json".source = ./antigravity.json;
    ".config/opencode/commands/adr.housekeeping.sh".source = ../agents/adr/housekeeping.sh;
  }
  // commandFiles
  // agentFiles
  // buildSkillFiles ".config/opencode/skills";
}

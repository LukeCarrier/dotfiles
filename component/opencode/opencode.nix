{
  config,
  pkgs,
  lib,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
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
  imports = [ ../agents ];

  home.packages = [
    opencode
    pkgs.opencode-desktop
  ]
  ++ userFacingPkgs;

  sops = {
    secrets = {
      github-mcp-token = {
        format = "yaml";
        key = "mcp/github";
      };
    };

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
      if [ -e "$target" ] && ${pkgs.jq}/bin/jq -e . "$target" >/dev/null 2>&1; then
        ${pkgs.jq}/bin/jq -s '.[0] * .[1] * .[2]' ${./opencode.json} "$target" "$mcp" > "$tmp"
      else
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' ${./opencode.json} "$mcp" > "$tmp"
      fi
      $DRY_RUN_CMD mv "$tmp" "$target"
    fi
  '';

  home.file = {
    ".config/opencode/AGENTS.md".source = ./AGENTS.md;
    ".config/opencode/agent/adrian.md".source = ./agent/adrian.md;
    ".config/opencode/agent/edmund.md".source = ./agent/edmund.md;
    ".config/opencode/agent/litterbox.md".source = ./agent/litterbox.md;
    ".config/opencode/agent/quest.md".source = ./agent/quest.md;
    ".config/opencode/agent/scout.md".source = ./agent/scout.md;
    ".config/opencode/antigravity.json".source = ./antigravity.json;
    ".config/opencode/commands/adr.housekeeping.sh".source = ../agents/adr/housekeeping.sh;
    ".config/opencode/skills/direnv/SKILL.md".source = ./skills/direnv/SKILL.md;
  }
  // commandFiles;
}

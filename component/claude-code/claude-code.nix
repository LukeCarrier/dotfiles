{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Build the claude-code configuration package
  agentConfig = import ../../lib/agent-config.nix {
    inherit pkgs config lib;
  };
  claudeCodeConfigPkg = agentConfig.claudeCodeConfig;

  agentsLib = import ../../lib/agents.nix { inherit lib; };
  substitute = agentsLib.substitute config lib;

  inherit (lib) getExe getExe';

  # Lower one entry of the shared programs.mcp.servers shape into Claude Code's
  # mcpServers schema.
  buildClaudeMcp =
    serverDef:
    let
      url = serverDef.url or null;
      command = serverDef.command or null;
      env = lib.mapAttrs (_: v: substitute (toString v)) (serverDef.env or { });
    in
    if url != null then
      {
        type = "http";
        url = substitute url;
      }
    else
      {
        type = "stdio";
        command = substitute (toString command);
      }
      // lib.optionalAttrs (serverDef.args or [ ] != [ ]) {
        args = map (a: substitute (toString a)) serverDef.args;
      }
      // lib.optionalAttrs (env != { }) { inherit env; };

  # Claude Code has no per-server `enabled` flag and no in-session toggle: a
  # server baked into ~/.claude.json is always active. The shared `enabled`
  # field the other tools honour therefore has no equivalent here. Instead we
  # render EVERY server to its own --mcp-config file and pick which to load at
  # launch time (see selectClaudeMcp below) — that's Claude Code's only
  # mechanism for default-off, opt-in-per-session servers.
  mcpDir = "${config.home.homeDirectory}/.config/claude-code/mcp";

  # Secrets are resolved by sops-nix at activation, so each per-server file is a
  # sops template; `substitute` has already turned @refs@ into sops placeholders.
  mcpTemplates = lib.mapAttrs' (
    name: serverDef:
    lib.nameValuePair "claude-code-mcp-${name}.json" {
      content = builtins.toJSON { mcpServers.${name} = buildClaudeMcp serverDef; };
      path = "${mcpDir}/${name}.json";
    }
  ) config.programs.mcp.servers;

  # fzf multi-select over the generated per-server files (TAB to toggle), then
  # launch Claude Code with just those servers. --strict-mcp-config means ONLY
  # the chosen files load (default: none), so ~/.claude.json stays free of
  # always-on servers. Extra args pass through: `claude-mcp -- -p "..."`.
  # Modelled on emed's selectMiniplatform fzf selector.
  selectClaudeMcp = pkgs.writeShellScriptBin "claude-mcp" ''
    fzf="${getExe pkgs.fzf}"
    jq="${getExe pkgs.jq}"
    claude="${getExe' pkgs.claude-code "claude"}"
    dir="${mcpDir}"

    mapfile -t servers < <(
      find "$dir" -maxdepth 1 -name '*.json' -exec basename {} .json \; | sort | \
        "$fzf" --multi --prompt 'mcp servers> ' \
          --preview "'$jq' '.mcpServers | map_values(if .env then .env |= map_values(\"***\") else . end)' '$dir/{}.json'"
    )

    args=()
    for server in "''${servers[@]}"; do
      args+=(--mcp-config "$dir/$server.json")
    done

    exec "$claude" --strict-mcp-config "''${args[@]}" "$@"
  '';
in
{
  imports = [ ../agents/agents.nix ];

  home.packages = with pkgs; [
    claude-code
    selectClaudeMcp
  ];

  sops = {
    # One --mcp-config file per server, with secrets resolved. selectClaudeMcp
    # picks among these at launch; nothing is merged into ~/.claude.json.
    templates = mcpTemplates;
  };

  # Copy the built configuration to ~/.claude during activation
  home.activation.claudeCodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.claude"
    $DRY_RUN_CMD cp -r ${claudeCodeConfigPkg} "$HOME/.claude"
    $DRY_RUN_CMD chmod -R u+w "$HOME/.claude"
  '';
}

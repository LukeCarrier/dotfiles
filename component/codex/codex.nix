{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentsLib = import ../../lib/agents.nix { inherit lib; };
  substitute = agentsLib.substitute config lib;

  # Lower a tool-agnostic command definition (config.agents.commands) into a
  # Codex custom prompt: YAML frontmatter followed by the shared body. Codex
  # prompts are flat Markdown files whose name becomes the slash command
  # directly, so the dotted name maps straight through (`adr.specify` ->
  # `/adr.specify`).
  buildCodexPrompt =
    cmd:
    let
      argumentHint = lib.concatMapStringsSep " " (p: "[${p.key}]") cmd.parameters;
      frontmatter = [
        "description: ${cmd.description}"
      ]
      ++ lib.optional (cmd.parameters != [ ]) "argument-hint: ${argumentHint}";
    in
    ''
      ---
      ${lib.concatStringsSep "\n" frontmatter}
      ---

    ''
    + cmd.body;

  promptFiles = lib.mapAttrs' (
    name: cmd:
    lib.nameValuePair ".codex/prompts/${name}.md" {
      source = pkgs.writeText "${name}.md" (buildCodexPrompt cmd);
    }
  ) config.agents.commands;

  # Lower the shared programs.mcp.servers shape into Codex's config.toml
  # `[mcp_servers.<name>]` tables, mirroring how goose/opencode lower the same
  # source. stdio servers carry command/args/env; remote servers carry a url.
  # Codex has a native `enabled` flag (default true), so the shared `enabled`
  # field (default false) passes straight through.
  tomlString = s: ''"'' + lib.replaceStrings [ ''\'' ''"'' ] [ ''\\'' ''\"'' ] s + ''"'';
  tomlArray = xs: "[" + lib.concatMapStringsSep ", " tomlString xs + "]";

  buildCodexMcp =
    name: serverDef:
    let
      url = serverDef.url or null;
      command = serverDef.command or null;
      env = lib.mapAttrs (_: v: substitute (toString v)) (serverDef.env or { });
      transport =
        if url != null then
          "url = ${tomlString (substitute url)}\n"
        else
          "command = ${tomlString (substitute (toString command))}\n"
          + lib.optionalString (serverDef.args or [ ] != [ ]) (
            "args = ${tomlArray (map (a: substitute (toString a)) serverDef.args)}\n"
          );
      # The env subtable must follow the parent table's inline keys.
      envBlock = lib.optionalString (env != { }) (
        "\n[mcp_servers.${name}.env]\n"
        + lib.concatStrings (lib.mapAttrsToList (k: v: "${k} = ${tomlString v}\n") env)
      );
    in
    # Defined but disabled in the file: codex can't hot-toggle MCP servers, and
    # activation is via CLI override instead (see the wrapper below), so the
    # config is a catalog and the wrapper enables the opted-in servers per run.
    ''
      [mcp_servers.${name}]
      enabled = false
    ''
    + transport
    + envBlock;

  mcpConfigToml = lib.concatStringsSep "\n" (
    lib.mapAttrsToList buildCodexMcp config.programs.mcp.servers
  );

  inherit (lib) getExe;

  # Codex can't hot-toggle MCP servers and a server enabled in config.toml is
  # active for every invocation. So config.toml is a disabled catalog and this
  # launcher fzf-multi-selects servers (TAB to toggle), enabling just those for
  # the run via codex's `-c` override (highest precedence). Extra args pass
  # through: `codex-mcp -- exec "..."`. Mirrors claude-mcp in component/claude-code.
  selectCodexMcp = pkgs.writeShellScriptBin "codex-mcp" ''
    fzf="${getExe pkgs.fzf}"
    yq="${getExe pkgs.yq-go}"
    jq="${getExe pkgs.jq}"
    codex="${getExe pkgs.codex}"
    config="$HOME/.codex/config.toml"

    mapfile -t servers < <(
      "$yq" -p toml -o json '.mcp_servers // {} | keys' "$config" 2>/dev/null | "$jq" -r '.[]' | sort | \
        "$fzf" --multi --prompt 'mcp servers> ' \
          --preview "'$yq' -p toml -o json '.mcp_servers.\"{}\"' '$config' | '$jq' 'if .env then .env |= map_values(\"***\") else . end'"
    )

    args=()
    for server in "''${servers[@]}"; do
      args+=(-c "mcp_servers.$server.enabled=true")
    done

    exec "$codex" "''${args[@]}" "$@"
  '';
in
{
  imports = [ ../agents ];

  home.packages = with pkgs; [
    codex
    selectCodexMcp
  ];

  sops = {
    secrets.github-mcp-token = {
      format = "yaml";
      key = "mcp/github";
    };

    # MCP servers carry secrets, so they're rendered to a staging file and
    # merged into the mutable config.toml at activation (below), rather than
    # owning the whole file — codex also keeps model settings and [profiles.*]
    # there. Servers stay declarative (enabled = false); enable per run with
    # `codex -c mcp_servers.<name>.enabled=true` or a profile.
    templates."codex-config-mcp.toml" = {
      content = mcpConfigToml;
      path = "${config.home.homeDirectory}/.codex/.config.toml.mcp";
    };
  };

  # Merge our [mcp_servers.*] into codex's mutable config.toml with yq-go's `*`:
  # existing then MCP (so MCP wins — store paths stay fresh and declarative),
  # preserving the user's other settings and any servers they added themselves.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    mcp="${config.home.homeDirectory}/.codex/.config.toml.mcp"
    target="$HOME/.codex/config.toml"
    if [ -r "$mcp" ]; then
      tmp="$(mktemp)"
      if [ -e "$target" ] && ${pkgs.yq-go}/bin/yq -p toml -o toml '.' "$target" >/dev/null 2>&1; then
        ${pkgs.yq-go}/bin/yq -p toml -o toml eval-all 'select(fi==0) * select(fi==1)' \
          "$target" "$mcp" > "$tmp"
      else
        cp "$mcp" "$tmp"
      fi
      $DRY_RUN_CMD mv "$tmp" "$target"
    fi
  '';

  # Codex ignores non-Markdown files in the prompts directory, so the shared
  # housekeeping helper rides along as a reference copy.
  home.file = promptFiles // {
    ".codex/prompts/adr.housekeeping.sh".source = ../agents/adr/housekeeping.sh;
  };
}

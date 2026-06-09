{ ... }:
# ADR planning-cycle command definitions. This is pure data: it populates the
# tool-agnostic `agents.commands` option (declared in lib/agents.nix), which
# component/goose and component/opencode lower into Goose recipes and opencode
# commands respectively — mirroring how programs.mcp.servers feeds both tools'
# MCP config from one shared shape.
#
# Each command's instruction body is shared verbatim by both tools and lives as
# Markdown under ./adr/<name>.md. The housekeeping helper script
# (./adr/housekeeping.sh) is referenced directly by each component.
let
  body = name: builtins.readFile (./adr + "/${name}.md");

  featureParams = [
    {
      key = "feature_name";
      description = "Feature name";
    }
    {
      key = "current_date";
      description = "Current date in YYYY-MM-DD format";
    }
  ];
in
{
  # Keyed by fully-qualified command name; the `adr.` namespace lives here in
  # the data, not in the renderers. Each component maps the dotted name onto its
  # own layout (e.g. opencode `adr.specify`, Goose/Claude `adr/specify`).
  config.agents.commands = {
    "adr.specify" = {
      title = "ADR Specify";
      description = "Generate or refine an ADR specification";
      body = body "specify";
      agent = "adrian";
    };
    "adr.plan" = {
      title = "ADR Plan";
      description = "Create a technical plan based on an ADR specification";
      body = body "plan";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.tasks" = {
      title = "ADR Tasks";
      description = "Break an ADR plan into implementable tasks";
      body = body "tasks";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.implement" = {
      title = "ADR Implement";
      description = "Implement an ADR following defined tasks";
      body = body "implement";
      maxTurns = 100;
      timeout = 600;
      parameters = featureParams;
      # agent left unset: owned by an implementation agent, not Adrian.
    };
    "adr.reflect" = {
      title = "ADR Reflect";
      description = "Capture learnings and improve the ADR process";
      body = body "reflect";
      agent = "adrian";
      parameters = featureParams;
    };
    "adr.housekeeping" = {
      title = "ADR Housekeeping";
      description = "Maintains adrs/README.md with all ADRs grouped by status";
      prompt = "Run the housekeeping script to regenerate the ADR README";
      body = body "housekeeping";
      maxTurns = 10;
      timeout = 60;
    };
  };
}

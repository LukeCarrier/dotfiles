{
  lib,
  pkgs,
  ...
}:
let
  body = name: builtins.readFile (./agent + "/${name}.md");
  adrBody = name: builtins.readFile (./adr + "/${name}.md");

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

  adrBuildSh = pkgs.writeShellScript "adr-build-sh" ''
    set -euo pipefail

    ADR_DIR="''${1:-$PWD}"
    SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"

    rendered=0

    for artifact in spec plan tasks retro; do
      toon_file="$ADR_DIR/$artifact.toon"
      md_file="$ADR_DIR/$artifact.md"
      jq_file="$SCRIPT_DIR/$artifact.jq"
      schema_file="$SCRIPT_DIR/$artifact.schema.json"

      if [[ ! -f "$toon_file" ]]; then continue; fi
      if [[ ! -f "$jq_file" ]]; then
        echo "Warning: no jq template for $artifact (expected $jq_file)" >&2
        continue
      fi

      tmp_json=$(mktemp)
      trap 'rm -f "$tmp_json"' EXIT

      toon --decode "$toon_file" > "$tmp_json"
      if [[ -f "$schema_file" ]]; then
        check-jsonschema --schemafile "$schema_file" "$tmp_json" >&2
      fi
      jq -f "$jq_file" -r "$tmp_json" > "$md_file"

      # Inline {{mermaid: <file>}} references as fenced code blocks
      if grep -q '{{mermaid: ' "$md_file" 2>/dev/null; then
        tmp_file=$(mktemp)
        while IFS= read -r line || [[ -n "$line" ]]; do
          if [[ "$line" =~ \{\{mermaid:\ ([^}]+)\}\} ]]; then
            mmd_file="$ADR_DIR/''${BASH_REMATCH[1]}"
            printf '\n```mermaid\n' >> "$tmp_file"
            if [[ -f "$mmd_file" ]]; then
              cat "$mmd_file" >> "$tmp_file"
            else
              echo "<!-- mermaid: file not found: ''${BASH_REMATCH[1]} -->" >> "$tmp_file"
            fi
            printf '\n```\n' >> "$tmp_file"
          else
            printf '%s\n' "$line" >> "$tmp_file"
          fi
        done < "$md_file"
        mv "$tmp_file" "$md_file"
      fi

      # Render {{wireloom: <file>}} references as SVG images
      if grep -q '{{wireloom: ' "$md_file" 2>/dev/null; then
        tmp_file=$(mktemp)
        while IFS= read -r line || [[ -n "$line" ]]; do
          if [[ "$line" =~ \{\{wireloom:\ ([^}]+)\}\} ]]; then
            wl_file="$ADR_DIR/''${BASH_REMATCH[1]}"
            if [[ -f "$wl_file" ]]; then
              wl_name="$(basename "$wl_file" .wireloom)"
              wl_slug="$(printf '%s' "$wl_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
              wireloom-render "$wl_file" -o "$ADR_DIR" --no-index >/dev/null
              printf '\n![%s](%s.svg)\n' "$wl_name" "$wl_slug" >> "$tmp_file"
            else
              echo "<!-- wireloom: file not found: ''${BASH_REMATCH[1]} -->" >> "$tmp_file"
            fi
          else
            printf '%s\n' "$line" >> "$tmp_file"
          fi
        done < "$md_file"
        mv "$tmp_file" "$md_file"
      fi

      echo "✓ $md_file"
      rendered=$((rendered + 1))
    done

    if [[ $rendered -eq 0 ]]; then
      echo "No .toon files found in $ADR_DIR" >&2
      exit 1
    fi
  '';
  adrDir = pkgs.runCommand "adr-fixtures" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir $out
    cp ${adrBuildSh} $out/build.sh
    cp ${./adr/spec.jq} $out/spec.jq
    cp ${pkgs.writeText "spec.schema.json" ''
      {
        "$schema": "https://json-schema.org/draft-07/schema#",
        "type": "object",
        "required": ["title", "status", "created", "author", "problem", "goals", "requirements", "nonFunctional", "acceptance"],
        "properties": {
          "title": { "type": "string" },
          "status": { "type": "string", "enum": ["draft", "proposed", "accepted", "rejected", "implemented", "superseded"] },
          "created": { "type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$" },
          "author": { "type": "string" },
          "context": { "type": "string" },
          "problem": { "type": "string" },
          "goals": { "type": "array", "items": { "type": "string" } },
          "nonGoals": { "type": "array", "items": { "type": "string" } },
          "requirements": {
            "type": "array", "items": {
              "type": "object", "required": ["id", "title", "slug", "description"],
              "properties": {
                "id": { "type": "string", "pattern": "^FR-\\d+$" },
                "title": { "type": "string" },
                "slug": { "type": "string", "pattern": "^[a-z][a-z0-9-]+$" },
                "description": { "type": "string" }
              }
            }
          },
          "nonFunctional": {
            "type": "array", "items": {
              "type": "object", "required": ["id", "title", "slug", "description"],
              "properties": {
                "id": { "type": "string", "pattern": "^NFR-\\d+$" },
                "title": { "type": "string" },
                "slug": { "type": "string", "pattern": "^[a-z][a-z0-9-]+$" },
                "description": { "type": "string" }
              }
            }
          },
          "acceptance": {
            "type": "array", "items": {
              "type": "object", "required": ["id", "title", "slug", "description"],
              "properties": {
                "id": { "type": "string", "pattern": "^AC-\\d+$" },
                "title": { "type": "string" },
                "slug": { "type": "string", "pattern": "^[a-z][a-z0-9-]+$" },
                "description": { "type": "string" }
              }
            }
          },
          "edgeCases": {
            "type": "array", "items": {
              "type": "object", "required": ["id", "title", "slug", "description"],
              "properties": {
                "id": { "type": "string", "pattern": "^EC-\\d+$" },
                "title": { "type": "string" },
                "slug": { "type": "string", "pattern": "^[a-z][a-z0-9-]+$" },
                "description": { "type": "string" }
              }
            }
          }
        }
      }
    ''} $out/spec.schema.json
    cp ${./adr/plan.jq} $out/plan.jq
    cp ${pkgs.writeText "plan.schema.json" ''
      {
        "$schema": "https://json-schema.org/draft-07/schema#",
        "type": "object",
        "required": ["title", "approach", "architecture", "technologies", "components"],
        "properties": {
          "title": { "type": "string" },
          "approach": { "type": "string" },
          "architecture": { "type": "string" },
          "technologies": {
            "type": "array", "items": {
              "type": "object", "required": ["name", "role"],
              "properties": {
                "name": { "type": "string" },
                "role": { "type": "string" }
              }
            }
          },
          "components": {
            "type": "array", "items": {
              "type": "object", "required": ["name", "purpose"],
              "properties": {
                "name": { "type": "string" },
                "purpose": { "type": "string" },
                "details": { "type": "string" }
              }
            }
          },
          "dataFlow": { "type": "string" },
          "deployment": { "type": "string" }
        }
      }
    ''} $out/plan.schema.json
    cp ${./adr/tasks.jq} $out/tasks.jq
    cp ${pkgs.writeText "tasks.schema.json" ''
      {
        "$schema": "https://json-schema.org/draft-07/schema#",
        "type": "object",
        "required": ["title", "items"],
        "properties": {
          "title": { "type": "string" },
          "items": {
            "type": "array", "items": {
              "type": "object",
              "required": ["id", "title", "criteria", "complexity", "effort"],
              "properties": {
                "id": { "type": "string" },
                "title": { "type": "string" },
                "description": { "type": "string" },
                "criteria": { "type": "string" },
                "complexity": { "type": "string", "enum": ["low", "medium", "high"] },
                "effort": { "type": "string" },
                "dependencies": { "type": "string" },
                "refs": { "type": "string" }
              }
            }
          }
        }
      }
    ''} $out/tasks.schema.json
    cp ${./adr/retro.jq} $out/retro.jq
    cp ${pkgs.writeText "retro.schema.json" ''
      {
        "$schema": "https://json-schema.org/draft-07/schema#",
        "type": "object",
        "required": ["title", "wentWell", "wentBadly", "improvements"],
        "properties": {
          "title": { "type": "string" },
          "wentWell": { "type": "array", "items": { "type": "string" } },
          "wentBadly": { "type": "array", "items": { "type": "string" } },
          "improvements": { "type": "array", "items": { "type": "string" } }
        }
      }
    ''} $out/retro.schema.json
    chmod +x $out/build.sh
    wrapProgram $out/build.sh --prefix PATH : "${lib.makeBinPath (with pkgs; [ toon-cli jq check-jsonschema wireloom-cli ])}"
  '';
  adrFixtures = {
    "build.sh" = "${adrDir}/build.sh";
    "spec.jq" = "${adrDir}/spec.jq";
    "spec.schema.json" = "${adrDir}/spec.schema.json";
    "plan.jq" = "${adrDir}/plan.jq";
    "plan.schema.json" = "${adrDir}/plan.schema.json";
    "tasks.jq" = "${adrDir}/tasks.jq";
    "tasks.schema.json" = "${adrDir}/tasks.schema.json";
    "retro.jq" = "${adrDir}/retro.jq";
    "retro.schema.json" = "${adrDir}/retro.schema.json";
  };

  # Review subagents: read-only on codebase, return findings via Task tool.
  reviewPermissions = {
    bash = "deny";
    edit = "deny";
    write = "deny";
    webfetch = "allow";
  };
in
{
  imports = [
    (import ../../lib/agents.nix { inherit lib; }).commandsModule
    (import ../../lib/agents.nix { inherit lib; }).definitionsModule
  ];

  sops.secrets.github-mcp-token = {
    format = "yaml";
    key = "mcp/github";
  };

  programs.mcp.servers.github = {
    command = lib.getExe pkgs.github-mcp-server;
    args = [
      "stdio"
      "--toolsets=default,actions,dependabot"
    ];
    env.GITHUB_PERSONAL_ACCESS_TOKEN = "@github-mcp-token@";
  };

  agents.skills = {
    align.source = ./skills/align/SKILL.md;
    code-review = {
      source = ./skills/code-review/SKILL.md;
      fixtures = {
        "report.sh" = ./skills/code-review/report.sh;
        "report.jq" = ./skills/code-review/report.jq;
      };
    };
    "command-not-found".source = ./skills/command-not-found/SKILL.md;
    jj.source = ./skills/jj/SKILL.md;
    jj-split-change.source = ./skills/jj-split-change/SKILL.md;
    jj-stack.source = ./skills/jj-stack/SKILL.md;
    nix.source = ./skills/nix/SKILL.md;
    pr-check-failure.source = ./skills/pr-check-failure/SKILL.md;
    toon.source = ./skills/toon/SKILL.md;
    wireframing = {
      source = ./skills/wireframing/SKILL.md;
      fixtures."grammar.md" = ./skills/wireframing/grammar.md;
    };
    resolve-dependabot-alert.source = ./skills/resolve-dependabot-alert/SKILL.md;
    writing-skills.source = ./skills/writing-skills/SKILL.md;
  };

  agents.commands = {
    "adr.specify" = {
      title = "ADR Specify";
      description = "Generate or refine an ADR specification";
      body = adrBody "specify";
      agent = "adrian";
      fixtures = adrFixtures;
    };
    "adr.plan" = {
      title = "ADR Plan";
      description = "Create a technical plan based on an ADR specification";
      body = adrBody "plan";
      agent = "adrian";
      parameters = featureParams;
      fixtures = adrFixtures;
    };
    "adr.tasks" = {
      title = "ADR Tasks";
      description = "Break an ADR plan into implementable tasks";
      body = adrBody "tasks";
      agent = "adrian";
      parameters = featureParams;
      fixtures = adrFixtures;
    };
    "adr.implement" = {
      title = "ADR Implement";
      description = "Implement an ADR following defined tasks";
      body = adrBody "implement";
      maxTurns = 100;
      timeout = 600;
      parameters = featureParams;
      fixtures = adrFixtures;
    };
    "adr.reflect" = {
      title = "ADR Reflect";
      description = "Capture learnings and improve the ADR process";
      body = adrBody "reflect";
      agent = "adrian";
      parameters = featureParams;
      fixtures = adrFixtures;
    };
    "adr.housekeeping" = {
      title = "ADR Housekeeping";
      description = "Maintains adrs/README.md with all ADRs grouped by status";
      prompt = "Run the housekeeping script to regenerate the ADR README";
      body = adrBody "housekeeping";
      maxTurns = 10;
      timeout = 60;
      fixtures = adrFixtures // {
        "adr.housekeeping.sh" = pkgs.runCommand "adr-housekeeping-sh" {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
          makeWrapper ${./adr/housekeeping.sh} "$out" --prefix PATH : "${lib.makeBinPath (with pkgs; [ toon-cli jq ])}"
        '';
      };
    };
  };

  agents.definitions = {
    adrian = {
      description = "Architecture Decision Records";
      mode = "primary";
      temperature = 0.1;
      body = body "adrian";
      permission = {
        bash = {
          "*" = "deny";
          "bash *build.sh *" = "allow";
        };
        edit = {
          "*" = "ask";
          "adrs/*" = "allow";
        };
        webfetch = "allow";
      };
    };

    edmund = {
      description = "Explorer";
      mode = "primary";
      temperature = 0.1;
      body = body "edmund";
      permission = {
        bash = "deny";
        edit = "deny";
        webfetch = "deny";
      };
    };

    litterbox = {
      description = "Litterbox";
      mode = "primary";
      temperature = 0.1;
      body = body "litterbox";
      tools = {
        "*" = false;
        read = true;
        edit = false;
        write = false;
        webfetch = true;
        google_search = true;
        question = true;
        todowrite = true;
        todoread = true;
        task = true;
        discard = true;
        extract = true;
        skill = true;
        "litterbox_*" = true;
      };
      permission = {
        "*" = "ask";
        read = "allow";
        edit = "deny";
        write = "deny";
        webfetch = "allow";
        google_search = "allow";
        question = "allow";
        todowrite = "allow";
        todoread = "allow";
        task = "allow";
        discard = "allow";
        extract = "allow";
        skill = "allow";
        "litterbox_*" = "allow";
        "litterbox_sandbox-create" = "ask";
      };
    };

    archie = {
      description = "Architecture Reviewer";
      mode = "subagent";
      temperature = 0.1;
      body = body "archie";
      permission = reviewPermissions;
    };

    ollie = {
      description = "Operations Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "ollie";
      permission = reviewPermissions;
    };

    paige = {
      description = "Product Reviewer";
      mode = "subagent";
      temperature = 0.1;
      body = body "paige";
      permission = reviewPermissions;
    };

    quest = {
      description = "QA Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "quest";
      permission = reviewPermissions;
    };

    scout = {
      description = "Security Engineer";
      mode = "subagent";
      temperature = 0.1;
      body = body "scout";
      permission = reviewPermissions;
    };
  };
}

{ lib, pkgs, ... }:
{
  xdg.mimeApps.defaultApplications =
    let app = "codium-url-handler.desktop";
  in {
    "x-scheme-handler/vscode" = app;
  };

  home.file.".vscode-oss/argv.json".text =
    let
      attrs = {
        # Scream at creepy Microsoft telemetry perverts
      	"enable-crash-reporter" = false;
      	"crash-reporter-id" = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

        # Default to GNOME/Seahorse via libsecret for credential storage on Linux.
        "password-store" = lib.mkIf pkgs.stdenv.isLinux "gnome-libsecret";
      };
    in builtins.toJSON attrs;

  programs.vscode =
    let
      globalExtensions =
        (with pkgs.open-vsx; [
          arcanis.vscode-zipfs
          arrterian.nix-env-selector
          bierner.markdown-mermaid
          bmalehorn.vscode-fish
          ciarant.vscode-structurizr
          editorconfig.editorconfig
          enkia.tokyo-night
          github.vscode-pull-request-github
          hediet.vscode-drawio
          jasew.vscode-helix-emulation
          jebbs.plantuml
          johnpapa.vscode-peacock
          jq-syntax-highlighting.jq-syntax-highlighting
        ])
        ++ (with pkgs.vscode-marketplace; [
          be5invis.vscode-icontheme-nomo-dark
          coder.coder-remote
          coenraads.disableligatures
          github.copilot
          github.copilot-chat
          io-github-oops418.nix-env-picker
          jjk.jjk
          kdl-org.kdl
          ms-vscode-remote.remote-containers
          ms-vsliveshare.vsliveshare
        ]);
      globalUserSettings = {
        # Privacy
        "amazonQ.telemetry" = false;
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        # Nagging
        "extensions.ignoreRecommendations" = true;
        "explorer.confirmDragAndDrop" = false;
        # Updates
        "update.mode" = "manual";
        "extensions.autoUpdate" = false;
        # Restore windows on re-open
        "window.restoreWindows" = "all";
        # Extension host
        "extensions.experimental.affinity" = {
          "jasew.vscode-helix-emulation" = 1;
        };
        # UI
        "gitlens.codeLens.enabled" = false;
        "window.titleBarStyle" = "custom";
        "window.commandCenter" = true;
        "window.autoDetectColorScheme" = true;
        "workbench.activityBar.location" = "top";
        "workbench.preferredDarkColorTheme" = "Tokyo Night Storm";
        "workbench.iconTheme" = "vs-nomo-dark"; # zhuangtongfa.material-theme
        "hediet.vscode-drawio.theme" = "dark"; # hediet.vscode-drawio
        "workbench.startupEditor" = "readme";
        "workbench.editor.highlightModifiedTabs" = true;
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.renderLineHighlight" = "all";
        "editor.renderLineHighlightOnlyWhenFocus" = true;
        "editor.bracketPairColorization.enabled" = true;
        "editor.lineNumbers" = "relative";
        # Fonts
        "editor.fontFamily" = "'MonaspiceKr NF', 'JetBrains Mono', 'Cascadia Code', Menlo, Monaco, Consolas, 'Courier New', monospace";
        "editor.fontSize" = 13;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', 'CaskaydiaCove Nerd Font', 'Cascadia Code PL', 'Cascadia Code', Menlo, Monaco, Consolas, 'Courier New', monospace";
        "terminal.integrated.fontSize" = 13;
        "editor.fontLigatures" = true;
        "disableLigatures.mode" = "Cursor";
        # Copy without formatting
        "editor.copyWithSyntaxHighlighting" = false;
        # Screencasting
        "screencastMode.keyboardOverlayTimeout" = 1200;
        "screencastMode.fontSize" = 24;
        # Editing
        "editor.comments.ignoreEmptyLines" = false;
        # Project colours
        "peacock.favoriteColors" = [
          {
            "name" = "Angular Red";
            "value" = "#dd0531";
          }
          {
            "name" = "Azure Blue";
            "value" = "#007fff";
          }
          {
            "name" = "GraphQL Pink";
            "value" = "#e535ab";
          }
          {
            "name" = "JavaScript Yellow";
            "value" = "#f9e64f";
          }
          {
            "name" = "Node Green";
            "value" = "#215732";
          }
          {
            "name" = "React Blue";
            "value" = "#61dafb";
          }
          {
            "name" = "Vue Green";
            "value" = "#42b883";
          }
          {
            "name" = "AWS Orange";
            "value" = "#ff9900";
          }
          {
            "name" = "Brain pink";
            "value" = "#cc005c";
          }
          {
            "name" = "Docker blue";
            "value" = "#0db7ed";
          }
          {
            "name" = "Go green";
            "value" = "#29beb0";
          }
          {
            "name" = "JS yellow";
            "value" = "#f7df1e";
          }
          {
            "name" = "Mint green";
            "value" = "#61c39f";
          }
          {
            "name" = "OpenTelemetry purple";
            "value" = "#4f62ad";
          }
          {
            "name" = "Rusty";
            "value" = "#c75240";
          }
          {
            "name" = "Shipcat blue";
            "value" = "#92d4e2";
          }
          {
            "name" = "Shocking purple";
            "value" = "#d57eeb";
          }
          {
            "name" = "Terraform purple";
            "value" = "#844fba";
          }
        ];
        "peacock.affectDebuggingStatusBar" = false;
        "peacock.affectStatusAndTitleBorders" = false;
        "peacock.affectStatusBar" = false;
        "peacock.affectTabActiveBorder" = false;
        "peacock.elementAdjustments" = {
          "activityBar" = "none";
        };
        "peacock.showColorInStatusBar" = false;
        # File assocations
        "files.associations" = {
          "*.fish" = "shell";
          "*.ipynb" = "jupyter.notebook.ipynb";
          "*.yml" = "yaml";
          "*.COBOL*" = "cobol";
          "*.COB*" = "cobol";
          "*.COBCOPY*" = "cobol";
          "*.COPYBOOK*" = "cobol";
          "*.COPY*" = "cobol";
          "*.PL1*" = "pl1";
          "*.PLI*" = "pl1";
          "*.INC*" = "pl1";
          "*.INCLUDE*" = "pl1";
          "*.JCL*" = "jcl";
          "*.ASM*" = "hlasm";
          "*.ASSEMBLE*" = "hlasm";
          "*.HLASM*" = "hlasm";
          "*.HLA*" = "hlasm";
          "*.hcl" = "terraform";
          "Vagrantfile" = "ruby";
          "Vagrantfile.*" = "ruby";
        };
        # Editor
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [80];
        "editor.wrappingIndent" = "deepIndent";
        "workbench.editor.closeEmptyGroups" = false;
        # Terminal
        "terminal.integrated.tabs.enabled" = true;
        "terminal.integrated.scrollback" = 0; # Use tmux instead
        "terminal.integrated.cursorBlinking" = true;
        # AI
        "chat.agent.enabled" = true;
        "github.copilot.chat.agent.autoFix" = true;
        "github.copilot.chat.agent.runTasks" = true;
        "mcp" = {
          "servers" = {
            "markitdown" = {
              "command" = "docker";
              "args" = [
                "run"
                "--rm"
                "-i"
                "markitdown-mcp:latest"
              ];
            };
          };
        };
        # Zen mode
        "zenMode.centerLayout" = false;
        "zenMode.fullScreen" = false;
        # CMake
        "cmake.configureOnOpen" = true;
        # Go
        "go.formatTool" = "goimports";
        "go.useLanguageServer" = true;
        "go.toolsManagement.autoUpdate" = true;
        # Kubernetes
        "vs-kubernetes" = {
          "checkForMinikubeUpgrade" = false;
        };
        # JSON
        "[json]" = {
          "editor.defaultFormatter" = "vscode.json-language-features";
        };
        # JSON with comments
        "[jsonc]" = {
          "editor.quickSuggestions" = {
            "strings" = true;
          };
          "editor.suggest.insertMode" = "replace";
        };
        # Rust
        "[rust]" = {
          "editor.rulers" = [100];
        };
        # Terraform
        "[terraform]" = {
          "editor.defaultFormatter" = "hashicorp.terraform";
        };
      };
    in {
      enable = true;
      package = (if pkgs.stdenv.isDarwin then pkgs.vscodium else pkgs.vscodium-fhs);
      profiles = {
        default = {
          extensions = globalExtensions;
          userSettings = globalUserSettings;
        };
        # DownTheStack-wealthgraph 
        LukeCarrier-denote = {
          extensions =
            globalExtensions
            ++ (with pkgs.open-vsx; [
              golang.go
            ]);
          userSettings = globalUserSettings;
        };
        LukeCarrier-infra = {
          extensions =
            globalExtensions
            ++ (with pkgs.open-vsx; [
              amazonwebservices.amazon-q-vscode
              aquasecurityofficial.trivy-vulnerability-scanner
              hashicorp.hcl
              hashicorp.terraform
              jnoortheen.nix-ide
              ms-azuretools.vscode-docker
              ms-kubernetes-tools.vscode-kubernetes-tools
              mtxr.sqltools
              mtxr.sqltools-driver-pg
              paulvarache.vscode-taskfile
              redhat.vscode-yaml
            ])
            ++ (with pkgs.vscode-marketplace; [
              ms-ossdata.vscode-pgsql
            ])
            ++ [ pkgs.vscode-marketplace."4ops".packer ];
          userSettings = globalUserSettings;
        };
        LukeCarrier-kotlin = {
          extensions =
            globalExtensions
            ++ (with pkgs.open-vsx; [
              fwcd.kotlin
            ]);
          userSettings = globalUserSettings;
        };
        LukeCarrier-rust = {
          extensions =
            globalExtensions
            ++ (with pkgs.open-vsx; [
              rust-lang.rust-analyzer
            ])
            ++ (with pkgs.vscode-extensions; [
              vadimcn.vscode-lldb
            ]);
            userSettings = globalUserSettings;
        };
      };
    };

  home.packages = lib.mkIf pkgs.stdenv.isLinux [ pkgs.vscode-insiders ];
}

# Dart
# dart-code.dart-code
# dart-code.flutter
# localizely.flutter-intl

# JS
# esbenp.prettier-vscode
# foxundermoon.shell-format
# prisma.prisma
# svelte.svelte-vscode

# Kotlin
# mathiasfrohlich.kotlin

# APIs
# graphql.vscode-graphql
# graphql.vscode-graphql-syntax
# jacobpfeifer.pfeifer-hurl
# pbkit.vscode-pbkit

# O11y
# joelalejandro.nrql-language
# michaelcsickles.honeycomb-derived
# randomchance.logstash

# C/C++
# josetr.cmake-language-support-vscode
# ms-vscode.cmake-tools
# twxs.cmake
# webfreak.debug

# C#
# ms-dotnettools.csharp
# ms-dotnettools.vscode-dotnet-runtime

# DevOps
# ms-azure-devops.azure-pipelines
# ms-azuretools.vscode-docker
# ms-kubernetes-tools.vscode-kubernetes-tools

# Python
# ms-python.debugpy
# ms-python.isort
# ms-python.python
# ms-python.vscode-pylance

# Data
# ms-toolsai.jupyter
# ms-toolsai.jupyter-keymap
# ms-toolsai.jupyter-renderers
# ms-toolsai.vscode-jupyter-cell-tags
# ms-toolsai.vscode-jupyter-slideshow

# PowerShell
# ms-vscode.powershell

# Remoting
# ms-vscode-remote.remote-containers
# ms-vscode-remote.remote-ssh
# ms-vscode-remote.remote-ssh-edit
# ms-vscode.remote-explorer
# mtxr.sqltools

# Support
# ms-vscode.vscode-speech
# redhat.vscode-commons

# Formats
# redhat.vscode-xml
# redhat.vscode-yaml
# tamasfe.even-better-toml
# wholroyd.jinja

# Rust
# rust-lang.rust-analyzer

# Scala
# scala-lang.scala

# Ruby
# shopify.ruby-lsp

# RPA
# robocorp.robocorp-code
# robocorp.robotframework-lsp

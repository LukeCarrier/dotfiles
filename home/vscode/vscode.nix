{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        editorconfig.editorconfig
        github.copilot
        github.copilot-chat
        github.vscode-pull-request-github
        hediet.vscode-drawio
        johnpapa.vscode-peacock
        ms-vsliveshare.vsliveshare

        # 1yib.svelte-bundle
        # 42crunch.vscode-openapi
        # 4ops.packer
        # 4ops.terraform
        # arcanis.vscode-zipfs
        # asvetliakov.vscode-neovim
        # be5invis.vscode-icontheme-nomo-dark
        # bierner.markdown-mermaid
        # bmalehorn.vscode-fish
        # carlos-algms.make-task-provider
        # chrischinchilla.vale-vscode
        # ciarant.vscode-structurizr
        # coder.coder-remote
        # coenraads.disableligatures
        # dart-code.dart-code
        # dart-code.flutter
        # daylerees.rainglow
        # enkia.tokyo-night
        # esbenp.prettier-vscode
        # foxundermoon.shell-format
        # fwcd.kotlin
        # golang.go
        # graphql.vscode-graphql
        # graphql.vscode-graphql-syntax
        # hashicorp.hcl
        # hashicorp.terraform
        # hediet.vscode-drawio
        # jacobpfeifer.pfeifer-hurl
        # jasew.vscode-helix-emulation
        # jebbs.plantuml
        # joelalejandro.nrql-language
        # josetr.cmake-language-support-vscode
        # jq-syntax-highlighting.jq-syntax-highlighting
        # kdl-org.kdl
        # localizely.flutter-intl
        # mathiasfrohlich.kotlin
        # michaelcsickles.honeycomb-derived
        # ms-azure-devops.azure-pipelines
        # ms-azuretools.vscode-docker
        # ms-dotnettools.csharp
        # ms-dotnettools.vscode-dotnet-runtime
        # ms-kubernetes-tools.vscode-kubernetes-tools
        # ms-python.debugpy
        # ms-python.isort
        # ms-python.python
        # ms-python.vscode-pylance
        # ms-toolsai.jupyter
        # ms-toolsai.jupyter-keymap
        # ms-toolsai.jupyter-renderers
        # ms-toolsai.vscode-jupyter-cell-tags
        # ms-toolsai.vscode-jupyter-slideshow
        # ms-vscode-remote.remote-containers
        # ms-vscode-remote.remote-ssh
        # ms-vscode-remote.remote-ssh-edit
        # ms-vscode.cmake-tools
        # ms-vscode.powershell
        # ms-vscode.remote-explorer
        # ms-vscode.vscode-speech
        # mtxr.sqltools
        # mtxr.sqltools-driver-sqlite
        # paulvarache.vscode-taskfile
        # pbkit.vscode-pbkit
        # prisma.prisma
        # randomchance.logstash
        # redhat.vscode-commons
        # redhat.vscode-xml
        # redhat.vscode-yaml
        # robocorp.robocorp-code
        # robocorp.robotframework-lsp
        # rust-lang.rust-analyzer
        # scala-lang.scala
        # shopify.ruby-lsp
        # svelte.svelte-vscode
        # tamasfe.even-better-toml
        # twxs.cmake
        # vadimcn.vscode-lldb
        # vscodevim.vim
        # webfreak.debug
        # wholroyd.jinja
        # zowe.vscode-extension-for-zowe
      ];
      userSettings = {
        # Privacy
        "telemetry.telemetryLevel" = "off";
        "redhat.telemetry.enabled" = false;
        # Nagging
        "extensions.ignoreRecommendations" = true;
        "explorer.confirmDragAndDrop" = false;
        # Restore windows on re-open
        "window.restoreWindows" = "all";
        # Extension host
        "extensions.experimental.affinity" = {};
        # UI
        "gitlens.codeLens.enabled" = false;
        "window.titleBarStyle" = "custom";
        "window.commandCenter" = true;
        "window.autoDetectColorScheme" = true;
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
        "editor.fontFamily" = "'JetBrains Mono', 'Cascadia Code', Menlo, Monaco, Consolas, 'Courier New', monospace";
        "editor.fontSize" = 13;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', 'CaskaydiaCove Nerd Font', 'Cascadia Code PL', 'Cascadia Code', Menlo, Monaco, Consolas, 'Courier New', monospace";
        "terminal.integrated.fontSize" = 13;
        "editor.fontLigatures" = true;
        "disableLigatures.mode" = "Cursor";
        # copy without formatting
        "editor.copywithsyntaxhighlighting" = false;
        # Screencasting
        "screencastMode.keyboardOverlayTimeout" = 1200;
        "screencastMode.fontSize" = 24;
        # Editing
        "editor.comments.ignoreEmptyLines" = false;
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
        # Spelling
        "cSpell.language" = "en-GB";
        "spellright.groupDictionaries" = false;
        "spellright.language" = ["en_GB"];
        # Editor
        "editor.renderWhitespace" = "all";
        "editor.rulers" = [80];
        "editor.wrappingIndent" = "deepIndent";
        "workbench.editor.closeEmptyGroups" = false;
        # Terminal
        "terminal.integrated.tabs.enabled" = true;
        "terminal.integrated.scrollback" = 0; # Use tmux instead
        "terminal.integrated.cursorBlinking" = true;
        # Zen mode
        "zenMode.centerLayout" = false;
        "zenMode.fullScreen" = false;
        # CMake
        "cmake.configureOnOpen" = true;
        # Go
        "go.formatTool" = "goimports";
        "go.useLanguageServer" = true;
        "go.toolsManagement.autoUpdate" = true;
        "gopls" = {
          "experimentalWorkspaceModule" = true;
        };
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
    };
  };
}

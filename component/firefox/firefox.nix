{ config, pkgs, ... }:
let
  firefoxpwa = pkgs.firefoxpwa.overrideAttrs (
    {
      postInstall ? "",
      ...
    }:
    {
      postInstall = postInstall + ''
        ln -s $out/share/firefoxpwa/runtime/firefox $out/share/firefoxpwa/runtime/librewolf
        ln -s $out/share/firefoxpwa/runtime/firefox-bin $out/share/firefoxpwa/runtime/librewolf-bin
      '';
    }
  );
  inherit (pkgs) lib stdenv;
in
{
  home.packages = lib.mkIf (!stdenv.isDarwin) [ firefoxpwa ];

  # FIXME: pure evaluation mode prevents this:
  # home.file.".librewolf/native-messaging-hosts".source = "${config.home.homeDirectory}/.mozilla/native-messaging-hosts";
  # So we have to:
  # ln -s ~/.mozilla/native-messaging-hosts ~/.librewolf/

  xdg.mimeApps.defaultApplications =
    let
      app = "librewolf.desktop";
    in
    {
      "text/html" = app;
      "x-scheme-handler/about" = app;
      "x-scheme-handler/chrome" = app;
      "x-scheme-handler/http" = app;
      "x-scheme-handler/https" = app;
      "x-scheme-handler/unknown" = app;
      "application/x-extension-htm" = app;
      "application/x-extension-html" = app;
      "application/x-extension-shtml" = app;
      "application/xhtml+xml" = app;
      "application/x-extension-xhtml" = app;
      "application/x-extension-xht" = app;
    };

  programs.librewolf =
    let
      browserActions = {
        bitwarden = "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action";
        multiAccountContainers = "_testpilot-containers-browser-action";
        refinedGitHub = "_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action";
        iStillDontCareAboutCookies = "idcac-pub_guus_ninja-browser-action";
        markDownload = "_1c5e4c6f-5530-49a3-b216-31ce7d744db0_-browser-action";
        progressiveWebAppsForFirefox = "firefoxpwa_filips_si-browser-action";
        readAloud = "_ddc62400-f22d-4dd3-8b4a-05837de53c2e_-browser-action";
        uBlockOrigin = "ublock0_raymondhill_net-browser-action";
        vimium = "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action";
        zotero = "zotero_chnm_gmu_edu-browser-action";
        developerButton = "developer-button";
      };
    in
    {
      enable = true;

      languagePacks = [
        "en-GB"
        "en-US"
      ];

      nativeMessagingHosts = lib.mkIf (!stdenv.isDarwin) [ firefoxpwa ];

      profiles.default = {
        isDefault = true;
        containers = {
          Personal = {
            id = 0;
            color = "orange";
            icon = "fingerprint";
          };
        };
        containersForce = true;
        extensions.packages = lib.mkDefault (
          with pkgs.nur.repos.rycee.firefox-addons;
          [
            bitwarden
            multi-account-containers
            markdownload
            istilldontcareaboutcookies
            read-aloud
            refined-github
            ublock-origin
            vimium
            zotero-connector
          ]
          ++ (if stdenv.isDarwin then [ ] else [ pkgs.nur.repos.rycee.firefox-addons.pwas-for-firefox ])
        );
        search = {
          default = "ddg";
          engines = {
            bing.metaData.hidden = true;
            ebay.metaData.hidden = true;
            google.metaData.hidden = true;

            "GitHub" = {
              definedAliases = [ "gh" ];
              urls = [
                { template = "https://github.com/{searchTerms}"; }
              ];
            };
            "GitHub/Search" = {
              definedAliases = [ "ghs" ];
              urls = [
                { template = "https://github.com/search?q={searchTerms}&type=repositories"; }
              ];
            };

            "nixpkgs/Options" = {
              definedAliases = [ "no" ];
              urls = [
                {
                  template = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
                }
              ];
            };
            "nixpkgs/Packages" = {
              definedAliases = [ "np" ];
              urls = [
                {
                  template = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
                }
              ];
            };
            "home-manager/Options" = {
              definedAliases = [ "hmo" ];
              urls = [
                { template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master"; }
              ];
            };

            "Perplexity" = {
              definedAliases = [ "p" ];
              urls = [
                { template = "https://www.perplexity.ai/search?focus=internet&q={searchTerms}"; }
              ];
            };

            "eMed/Go" = {
              definedAliases = [ "go" ];
              urls = [
                { template = "https://api.eu-west-2.emed.health/go-url/{searchTerms}"; }
              ];
            };
          };
        };
        settings = {
          "extensions.autoDisableScopes" = 0;

          "browser.compactmode.show" = true;
          "browser.uidensity" = 1;
          "browser.toolbars.bookmarks.visibility" = "never";
          "sidebar.main.tools" = "aichat,syncedtabs,history,bookmarks";
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "browser.pageActions.persistedActions" = {
            "ids" = [
              "bookmark"
              "_testpilot-containers"
              "firefoxpwa_filips_si"
            ];
            "idsInUrlbar" = [
              "_testpilot-containers"
              "firefoxpwa_filips_si"
              "bookmark"
            ];
            "idsInUrlbarPreProton" = [ ];
            "version" = 1;
          };
          "browser.uiCustomization.horizontalTabsBackup" = { };
          "browser.uiCustomization.horizontalTabstrip" = [
            "tabbrowser-tabs"
            "new-tab-button"
            "alltabs-button"
          ];
          "browser.uiCustomization.navBarWhenVerticalTabs" = lib.mkDefault [
            "sidebar-button"
            "back-button"
            "forward-button"
            "stop-reload-button"
            "customizableui-special-spring3"
            "urlbar-container"
            "vertical-spacer"
            "alltabs-button"
            "firefox-view-button"
            "unified-extensions-button"
            browserActions.bitwarden
            browserActions.zotero
          ];
          "browser.uiCustomization.state" = {
            "placements" = {
              "widget-overflow-fixed-list" = [ ];
              "unified-extensions-area" = with browserActions; [
                multiAccountContainers
                iStillDontCareAboutCookies
                markDownload
                refinedGitHub
                progressiveWebAppsForFirefox
                readAloud
                uBlockOrigin
                vimium
              ];
              "nav-bar" =
                config.programs.librewolf.profiles.default.settings."browser.uiCustomization.navBarWhenVerticalTabs";
              "toolbar-menubar" = [ "menubar-items" ];
              "TabsToolbar" = [ ];
              "vertical-tabs" = [ "tabbrowser-tabs" ];
              "PersonalToolbar" = [
                "import-button"
                "personal-bookmarks"
              ];
            };
            # Extensions here won't be automatically pinned to the menu bar.
            "seen" = builtins.attrValues browserActions;
            "dirtyAreaCache" = [
              "unified-extensions-area"
              "nav-bar"
              "TabsToolbar"
              "vertical-tabs"
              "PersonalToolbar"
            ];
            "currentVersion" = 21;
            "newElementCount" = 4;
          };

          "browser.ml.enable" = true;

          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.tabs.groups.enabled" = true;

          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
          "privacy.clearOnShutdown_v2.cache" = false;
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        };
      };
    };
}

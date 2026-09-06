{
  jjConfig,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    jujutsu
    tuicr
  ];

  programs = {
    jjui = {
      enable = true;
      settings = {
        actions = [
          {
            name = "revisions.diff";
            lua = ''
              exec_shell("tuicr tui --revisions " .. context.commit_id())
            '';
          }

          {
            name = "revisions.details.diff";
            lua = ''
              exec_shell("tuicr tui --revisions " .. context.commit_id() .. " --path " .. context.file())
            '';
          }
        ];
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Luke Carrier";
          email = "luke@carrier.family";
        };

        signing = {
          behavior = "own";
          backend = "ssh";
          key = jjConfig.signing.key;
        };

        ui = {
          show-cryptographic-signatures = true;
        };

        "template-aliases" = {
          "format_short_cryptographic_signature(sig)" = ''
            if(sig,
              sig.status(),
              "(no sig)",
            )
          '';
        };
      };
    };
  };
}

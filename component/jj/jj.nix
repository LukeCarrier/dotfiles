{
  jjConfig,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    jjui
    jujutsu
  ];

  programs.jujutsu = {
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
}

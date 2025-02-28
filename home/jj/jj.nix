{
  jjConfig,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    jujutsu
    lazyjj
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
        sign-all = true;
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

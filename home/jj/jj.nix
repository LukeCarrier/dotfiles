{ pkgs, ... }:
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
    };
  };
}

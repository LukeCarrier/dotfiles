{ ... }:
{
  services.greetd.enable = true;

  services.displayManager.regreet = {
    enable = true;
    cageArgs = [
      "-m"
      "last"
      "-s"
    ];
    settings = {
      GTK.application_prefer_dark_theme = true;
    };
  };
}

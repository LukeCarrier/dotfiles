{ ... }:
{
  services.greetd.enable = true;

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      appearance.scheme = "Noctalia";
      cursor.size = 24;
      keyboard.layout = "us";
    };
  };
}

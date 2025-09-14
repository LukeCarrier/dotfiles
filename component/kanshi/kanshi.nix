{ pkgs, ... }:
{
  home.packages = [ pkgs.kanshi ];

  services.kanshi = {
    enable = true;
    package = pkgs.kanshi;
    # List outputs with:
    # - Hyprland: hyprctl monitors all
    # - Niri: niri msg outputs
    settings = [
      # Laptop's own display
      {
        output.criteria = "eDP-1";
        output.mode = "2880x1920@120Hz";
        output.adaptiveSync = true;
        output.scale = 1.25;
        output.transform = null;
      }

      # Projector
      {
        output.criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
        output.mode = "3840x2160@60Hz";
        output.adaptiveSync = false;
        output.scale = 1.5;
        output.transform = null;
      }

      # My office
      {
        output.criteria = "Samsung Electric Company U32J59x HTPK702789";
        output.mode = "3840x2160@60Hz";
        output.adaptiveSync = false;
        output.scale = 1.25;
        output.transform = null;
      }
      {
        output.criteria = "Samsung Electric Company U32J59x HTPK602008";
        output.mode = "3840x2160@30Hz";
        output.adaptiveSync = false;
        output.scale = 1.25;
        output.transform = null;
      }

      # Michael's office
      {
        output.criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
        output.mode = "1920x1080@60Hz";
        output.adaptiveSync = false;
        output.scale = 1.0;
        output.transform = null;
      }

      {
        profile.name = "mobile";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "peacehavenLounge";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Anker Innovations Limited CosmosLaser4k 0x00000001";
            status = "enable";
            position = "0,3600";
          }
        ];
      }
      {
        profile.name = "peacehavenDockedClosed";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK702789";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "3072,0";
          }
        ];
      }
      {
        profile.name = "peacehavenDockedOpen";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U32J59x HTPK702789";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "3072,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "4224,1728";
          }
        ];
      }
      {
        profile.name = "peacehavenSidecar";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U32J59x HTPK602008";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "768,1728";
          }
        ];
      }
      {
        profile.name = "peacehavenMichaelDocked";
        profile.outputs = [
          {
            criteria = "Ancor Communications Inc ASUS VS247 C8LMTF177755";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "enable";
            position = "1920,540";
          }
        ];
      }
    ];
  };
}

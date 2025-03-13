{ ... }: {  
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        modules-center = [
          "clock"
          "privacy"
          "mpris"
        ];
        modules-right = [
          "battery"
          "power-profiles-daemon"
          "wireplumber"
          "bluetooth"
          "network"
          "idle_inhibitor"
          "tray"
        ];

        clock = {
          format = "{:%Y-%m-%d %H:%M (%Z)}";
          tooltip-format = ''
            <tt>{tz_list}</tt>
            <tt></tt>
            <tt>{calendar}</tt>
          '';
          timezones = [
            "Europe/London"
            "Etc/UTC"
            "Europe/Warsaw"
            "America/Miami"
            "Asia/New_Delhi"
          ];
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };
        privacy = {
          icon-size = 15;
        };
        battery = {
          format = "{icon} {capacity}%";
          format-icons = {
            full = "";
            good = "";
            half = "";
            warning = "";
            critical = "";
          };
          full_at = 80;
          states = {
            full = 100;
            good = 80;
            half = 60;
            warning = 40;
            critical = 20;
          };
        };
        power-profiles-daemon = {
          format-icons = {
            default = "🐾";
            performance = "🦄";
            balanced = "🦡";
            power-saver = "🦥";
          };
        };
        wireplumber = {
          on-click = "helvum";
          format = "🔉 {volume}%";
          format-muted = "🔇";
        };
        bluetooth = {
          on-click = "blueman-manager";
        };
        network = {
          on-click = "nm-connection-editor";
          tooltip-format = ''
            <tt>Interface: {ifname}</tt>
            <tt>Primary IP: {ipaddr}</tt>
            <tt>Gateway: {gwaddr}</tt>
          '';
          format-ethernet = "🌐 {ifname}";
          format-wifi = "🛜 {essid}";
          tooltip-fprmat-wifi = ''
            <tt>eSSID: {essid}</tt>
            <tt>Frequency: {frequency}</tt>
            <tt>Interface: {ifname}</tt>
            <tt>Primary IP: {ipaddr}</tt>
            <tt>Gateway: {gwaddr}</tt>
            <tt>Signal strength: {signalStrength}</tt>
            <tt>Signal strength (dBm): {signalStrengthD}</tt>
          '';
          format-linked = "🖇️ {ifname}";
          format-disconnected = "😱";
          tooltip-format-disconnected = "No network connection";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "☕️";
            deactivated = "🍻";
          };
        };
      };
    };
    style = builtins.readFile ./waybar.css;
  };
}

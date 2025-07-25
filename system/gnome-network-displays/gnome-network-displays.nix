{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    glib-networking
    gnome-network-displays
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];
  
  networking.firewall = {
    allowedTCPPorts = [ 7236 ];
    allowedTCPPortRanges = [
      { from = 32768; to = 60999; }
    ];
  };
}

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    glib-networking
    gnome-network-displays
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

  networking.firewall = {
    # 7236/tcp: Miracast/WFD RTSP control. 5353/udp: mDNS sink discovery
    # (Google Cast, MICE) - usually already open via services.avahi.openFirewall,
    # repeated here so the component is self-contained.
    allowedTCPPorts = [ 7236 ];
    allowedUDPPorts = [ 5353 ];
    # The sink connects back to GNOME Network Displays' GStreamer server on an
    # OS-ephemeral port: TCP for the Google Cast HTTP stream, UDP for Miracast
    # RTP/RTCP media. Without these, discovery succeeds but playback fails.
    allowedTCPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
  };
}

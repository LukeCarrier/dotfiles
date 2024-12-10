{ ... }:
{
  networking.firewall = {
    # Log packets dropped due to reverse path failures to kernel ring buffer.
    logReversePathDrops = true;

    # If the below doesn't work, be more permissive.
    #checkReversePath = false;
    #checkReversePath = "loose";

    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
  };
}

{self, ...}: {
  flake.lib.renderIpv6 = device:
    self.lib.mkSubTitle device "RESET"
    + ''
    ''
    + self.lib.mkSubTitle device "Settings"
    + (
      if device.ipv6.routing
      then "ipv6 unicast-routing\n"
      else "no ipv6 unicast-routing\n"
    );
}

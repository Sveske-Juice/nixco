{
  self,
  lib,
}: device: ifname: value:
self.mkSubTitle device "Interface ${ifname}"
+ (
  if value.range
  then "interface range ${ifname}\n"
  else "interface ${ifname}\n"
)
+ lib.optionalString (value.description != null) "description ${value.description}\n"
+ lib.optionalString (value.encapsulation != null) "encapsulation dot1q ${toString value.encapsulation.vlanId}\n"
+ (
  if value.switchport != null
  then self.renderSwitchport value
  else ""
)
+
# IPv4
lib.optionalString (value.ip != null)
(
  (lib.optionalString (value.ip.address != null && value.ip.address == "dhcp") "ip address dhcp\n")
  + (lib.optionalString (value.ip.address != null && builtins.isAttrs value.ip.address) "ip address ${value.ip.address.address} ${value.ip.address.subnetmask}\n")
  + (lib.optionalString (value.ip.ipHelper != null) "ip helpher-address ${value.ip.ipHelper}\n")
)
+
# IPv6
lib.optionalString (value.ipv6 != null)
(
  (lib.optionalString (value.ipv6.linkLocal != null) "ipv6 address ${value.ipv6.linkLocal} link-local\n")
  + (builtins.concatStringsSep "" (builtins.map (
      addr: "ipv6 address ${addr}\n"
    )
    value.ipv6.addresses))
  +
  # DHCPv6
  (
    lib.optionalString (value.ipv6.dhcp != null)
    (
      lib.optionalString (value.ipv6.dhcp.relay != null)
      ''
        ipv6 dhcp relay destination ${value.ipv6.dhcp.relay.destination} ${lib.optionalString (value.ipv6.dhcp.relay.interface != null) value.ipv6.dhcp.relay.interface}
      ''
    )
  )
)
+ lib.optionalString (value.channelGroup != null) "channel-group ${toString value.channelGroup.groupNumber} mode ${value.channelGroup.mode}\n"
+ lib.optionalString (value.accessGroup != null) "access-group ${
  if value.accessGroup.id != null
  then toString value.accessGroup.id
  else value.accessGroup.name
} ${value.accessGroup.interface}\n"
+ (
  if value.shutdown
  then "shutdown\n"
  else "no shutdown\n"
)

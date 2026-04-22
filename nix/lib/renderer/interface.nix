{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib = {
    expandInterfaces = interfaces:
      lib.concatMapAttrs (
        name: value: let
          segments = map lib.trim (lib.splitString "," name);

          expandSegment = seg: let
            parts = lib.splitString "/" seg;
            prefix = lib.concatStringsSep "/" (lib.init parts);
            lastPart = lib.last parts;
            rangeParts = lib.splitString "-" lastPart;
            start = lib.toInt (builtins.head rangeParts);
            end = lib.toInt (lib.last rangeParts);
          in
            map (n: "${prefix}/${toString n}") (lib.range start end);

          expanded = lib.concatMap expandSegment segments;
        in
          builtins.listToAttrs (map (n: {
            name = n;
            inherit value;
          })
            expanded)
      )
      interfaces;
    renderSwitchport = ifvalue:
      if ifvalue.switchport.enable
        then
        (
          ''
          switchport
          switchport mode ${ifvalue.switchport.mode}
          ''
          + lib.optionalString (!ifvalue.switchport.negotiate) "switchport nonegotiate\n"
          + lib.optionalString (ifvalue.switchport.mode == "access")
          "switchport access vlan ${toString ifvalue.switchport.vlan}\n"
          + lib.optionalString (ifvalue.switchport.mode == "trunk")
          (
            ''
            switchport trunk native vlan ${toString ifvalue.switchport.trunk.nativeVLAN}
            ''
            + (
              if (builtins.isList ifvalue.switchport.trunk.allowed)
                then "switchport trunk allowed vlan " + builtins.concatStringsSep "," (map toString ifvalue.switchport.trunk.allowed) + "\n"
              else ''
              switchport trunk allowed vlan ${ifvalue.switchport.trunk.allowed}
                ''
            )
          )
          + lib.optionalString (ifvalue.switchport.portSecurity != null) (
            ''
            switchport port-security
            switchport port-security maximum ${toString ifvalue.switchport.portSecurity.maximum}
            switchport port-security violation ${ifvalue.switchport.portSecurity.violation}
            ''
            + lib.optionalString ((builtins.length ifvalue.switchport.portSecurity.secureMacAddresses) != 0) (
              builtins.concatStringsSep "" (map (addr: "switchport port-security mac-address ${addr}\n") ifvalue.switchport.portSecurity.secureMacAddresses)
            )
            + lib.optionalString ifvalue.switchport.portSecurity.stickyMac
            "switchport port-security mac-address sticky\n"
            + lib.optionalString (ifvalue.switchport.portSecurity.aging != null)
            (
              ''
              switchport port-security aging time ${toString ifvalue.switchport.portSecurity.aging.time}
              switchport port-security aging type ${ifvalue.switchport.portSecurity.aging.type}
              ''
              + (lib.optionalString ifvalue.switchport.portSecurity.aging.static
                "switchport port-security aging static")
            )
          )
        )
      else "no switchport\n";
    renderInterface = device: ifname: ifvalue: let
      body = 
        lib.optionalString (ifvalue.description != null) "description ${ifvalue.description}\n"
        + lib.optionalString (ifvalue.encapsulation != null) "encapsulation dot1q ${toString ifvalue.encapsulation.vlanId}\n"
        + (
          if ifvalue.switchport != null && device.deviceSpec.deviceType == "switch"
            then self.lib.renderSwitchport ifvalue
          else ""
        )
        +
        # IPv4
        lib.optionalString (ifvalue.ip != null)
        (
          (lib.optionalString (ifvalue.ip.address != null && ifvalue.ip.address == "dhcp") "ip address dhcp\n")
          + (lib.optionalString (ifvalue.ip.address != null && builtins.isAttrs ifvalue.ip.address) "ip address ${ifvalue.ip.address.addr} ${ifvalue.ip.address.netmask}\n")
          + (lib.optionalString (ifvalue.ip.helperAddresses != null) (lib.concatMapStrings (addr: "ip helper-address ${addr}\n") ifvalue.ip.helperAddresses))
        )
        +
        # IPv6
        lib.optionalString (ifvalue.ipv6 != null)
        (
          (lib.optionalString (ifvalue.ipv6.linkLocal != null) "ipv6 address ${ifvalue.ipv6.linkLocal} link-local\n")
          + (builtins.concatStringsSep "" (map (
            addr: "ipv6 address ${addr}\n"
          )
            ifvalue.ipv6.addresses))
          +
          # DHCPv6
          (
            lib.optionalString (ifvalue.ipv6.dhcp != null)
            (
              lib.optionalString (ifvalue.ipv6.dhcp.relay != null)
              ''
            ipv6 dhcp relay destination ${ifvalue.ipv6.dhcp.relay.destination} ${lib.optionalString (ifvalue.ipv6.dhcp.relay.interface != null) ifvalue.ipv6.dhcp.relay.interface}
              ''
            )
          )
        )
        + lib.optionalString (ifvalue.channelGroup != null) "channel-group ${toString ifvalue.channelGroup.groupNumber} mode ${ifvalue.channelGroup.mode}\n"
        + lib.optionalString (ifvalue.ip.accessGroup != null) "access-group ${
        if ifvalue.ip.accessGroup.id != null
          then toString ifvalue.ip.accessGroup.id
        else ifvalue.ip.accessGroup.name
      } ${ifvalue.ip.accessGroup.interface}\n"
        + ifvalue.extraPostConfig
        + (
          if ifvalue.shutdown
            then "shutdown\n"
          else "no shutdown\n"
        );
    in
      self.lib.mkSubTitle device "Interface ${ifname}"
      + "interface ${ifname}\n"
      + self.lib.indentLines body;
    renderInterfaces = device: let
      expandedInterfaces = self.lib.expandInterfaces device.interfaces;
      sortedInterfaces = builtins.sort (a: b: a.value.priority < b.value.priority) (map (name: {
        inherit name;
        value = expandedInterfaces.${name};
      }) (builtins.attrNames expandedInterfaces));
    in
      lib.concatStringsSep "\n" (map (
        value:
        self.lib.renderInterface device value.name value.value
      )
        sortedInterfaces);
  };
}

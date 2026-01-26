{
  render = {lib, ...}: device: let
    renderRoute = lib: route:
      (
        if route.ipv6
        then "ipv6 "
        else "ip "
      )
      + "route "
      + (
        if route.ipv6
        then route.destination
        else "${route.destination.address} ${route.destination.subnetmask}"
      )
      + " "
      + (lib.optionalString (route.exitInterface != null) "${route.exitInterface} ")
      + (lib.optionalString (route.nextHop != null) "${route.nextHop} ")
      + (toString route.distance);
    renderSwitchport = lib: value:
      ''
        switchport mode ${value.switchport.mode}
      ''
      + lib.optionalString (!value.switchport.negotiate) "switchport nonegotiate\n"
      + lib.optionalString (value.switchport.mode == "access")
      "switchport access vlan ${toString value.switchport.vlan}\n"
      + lib.optionalString (value.switchport.mode == "trunk")
      ''
        switchport trunk native vlan ${toString value.switchport.trunk.nativeVLAN}
        switchport trunk allowed vlan ${value.switchport.trunk.allowed}
      ''
      + lib.optionalString (value.switchport.portSecurity != null) (
        ''
          switchport port-security
          switchport port-security maximum ${toString value.switchport.portSecurity.maximum}
          switchport port-security violation ${value.switchport.portSecurity.violation}
        ''
        + lib.optionalString ((builtins.length value.switchport.portSecurity.secureMacAddresses) != 0) (
          builtins.concatStringsSep "" (map (addr: "switchport port-security mac-address ${addr}\n") value.switchport.portSecurity.secureMacAddresses)
        )
        + lib.optionalString value.switchport.portSecurity.stickyMac
        "switchport port-security mac-address sticky\n"
        + lib.optionalString (value.switchport.portSecurity.aging != null)
        (
          ''
            switchport port-security aging time ${toString value.switchport.portSecurity.aging.time}
            switchport port-security aging type ${value.switchport.portSecurity.aging.type}
          ''
          + (lib.optionalString value.switchport.portSecurity.aging.static
            "switchport port-security aging static")
        )
      );
    renderInterface = lib: ifname: value:
      mkSubTitle "Interface ${ifname}"
      + (
        if isRange ifname
        then "interface range ${ifname}\n"
        else "interface ${ifname}\n"
      )
      + lib.optionalString (value.description != null) "description \"${value.description}\"\n"
      + lib.optionalString (!value.shutdown) "no shutdown\n"
      + (
        if value.switchport != null
        then renderSwitchport lib value
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
      + lib.optionalString (value.channelGroup != null) "channel-group ${toString value.channelGroup.groupNumber} mode ${value.channelGroup.mode}\n";
    isRange = key:
      builtins.match ".*[-,].*" key != null;
    mkSubTitle = title: lib.optionalString device.comments "!==== ${title} ====!\n";
    mkTitle = title:
      lib.optionalString device.comments ''
        ! +----------------------------+
        ! ${title}
        ! +----------------------------+
      '';
  in
    mkSubTitle "Pre config"
    + device.extraPreConfig
    + lib.optionalString (device.hostname != null) "hostname ${device.hostname}\n"
    + mkTitle "Banners"
    + ''
      banner motd #${device.banner.motd}#
      banner login #${device.banner.login}#
      banner config-save #${device.banner.configSave}#
      banner exec #${device.banner.exec}#
      banner incoming #${device.banner.incoming}#
      banner prompt-timeout #${device.banner.promptTimeout}#
      banner slip-ppp #${device.banner.slipPPP}#
    ''
    + mkTitle "VLANs"
    + (builtins.concatStringsSep "" (builtins.map (vlan: ''
        vlan ${toString vlan.id}
        name ${vlan.name}
      '')
      device.vlans))
    + lib.optionalString ((builtins.length device.vlans) != 0) "exit\n"
    + mkTitle "Interfaces"
    + mkSubTitle "RESET"
    + builtins.concatStringsSep "" (builtins.map (int: ''
        default interface ${int}
      '')
      device.deviceSpec.interfaces)
    + lib.concatMapAttrsStringSep "\n" (
      ifname: value:
        renderInterface lib ifname value
    )
    device.interfaces
    + mkTitle "Routing"
    + mkSubTitle "Static Routes"
    + builtins.concatStringsSep "\n" (builtins.map (
        route:
          renderRoute lib route
      )
      device.routes)
    +
    lib.optionalString ((builtins.stringLength device.extraPostConfig) != 0) ''
      end
      configure terminal
      ${mkSubTitle "Post Config"}
      ${device.extraPostConfig}
    '';
}

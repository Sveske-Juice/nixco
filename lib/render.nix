{
  render = {lib, ...}: device: let
    sysloglevel = "critical";
    renderPCEEM = pcInterfaces: let
      interfaceConfigs = builtins.concatStringsSep "\n" (lib.mapAttrsToList (
        intname: intvalue: renderInterface lib intname intvalue)
      pcInterfaces);
      lines = builtins.filter (l: l != "") (lib.splitString "\n" interfaceConfigs);
    in ''
      event manager applet FIX_PC
      event syslog pattern "SYS-5-RESTART" occurs 1 maxrun 120
      action 0.1 syslog priority ${sysloglevel} msg "NIXCO: RUNNING PORT-CHANNEL FIX EEM AFTER 30s"
      action 0.2 wait 30
      action 0.3 cli command "enable"
      action 0.4 cli command "configure terminal"
      ! Self-destruction
      action 0.5 cli command "no event manager applet FIX_PC"
    ''
    +
    builtins.concatStringsSep "\n" (lib.lists.imap1 (i: line: ''action 1.${toString i} cli command "${line}"'') lines)
    +
    "\n"
    +
    ''
    action 2.1 syslog priority ${sysloglevel} msg "NIXCO: DONE WITH FIXING PORT CHANNELS"
    '';
    renderKeyCmd = key:
    "crypto key generate ${key.type} "
    +
    (if key.type == "rsa" then
      "modulus ${toString key.rsaOpts.modulus} "
      +
      lib.optionalString (key.rsaOpts.label != null) "label ${key.rsaOpts.label} "
    else # ec
      "keysize ${toString key.ecOpts.keysize} "
    );
    renderKeyEEM = idx: key: let
      keyCmd = renderKeyCmd key;
      appletName = "SSH_KEY_GEN_${toString idx}";
    in ''
      event manager applet ${appletName}
      event syslog pattern "SYS-5-RESTART" occurs 1 maxrun 60
      action 1 wait 10
      action 2 cli command "enable"
      action 3 cli command "configure terminal"
      ! Self-destruction
      action 4 cli command "no event manager applet ${appletName}"
      action 5 cli command "end"
      action 6 cli command "${keyCmd}"
    '';
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
        switchport
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
      + lib.optionalString (value.description != null) "description ${value.description}\n"
      + lib.optionalString (value.encapsulation != null) "encapsulation dot1q ${toString value.encapsulation.vlanId}\n"
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
      + lib.optionalString (value.channelGroup != null) "channel-group ${toString value.channelGroup.groupNumber} mode ${value.channelGroup.mode}\n"
      + lib.optionalString (value.accessGroup != null) "access-group ${if value.accessGroup.id != null then toString value.accessGroup.id else value.accessGroup.name} ${value.accessGroup.interface}\n"
      + (if value.shutdown then "shutdown\n" else "no shutdown\n")
    ;

    isRange = key:
      builtins.match ".*[-,].*" key != null;
    mkSubTitle = title: lib.optionalString device.comments "!==== ${title} ====!\n";
    mkTitle = title:
      lib.optionalString device.comments ''
        ! +----------------------------+
        ! ${title}
        ! +----------------------------+
      '';

    renderACLs = device:
      mkSubTitle "RESET"
      + ''
        ! ACLs cant be reset automaticaly, to reset you must use a strategy which reloads the device
      ''
      + mkSubTitle "Standard ACLs"
      + (builtins.concatStringsSep "\n" (map (
          acl:
            ''
              ip access-list standard ${
                if acl.name != null
                then acl.name
                else toString acl.id
              }
            ''
            + (builtins.concatStringsSep "\n" (map (
                rule:
                  lib.optionalString (rule.remark != null) "remark \"${rule.remark}\"\n"
                  + ''
                    ${rule.action} ${
                      if rule.source == "any"
                      then "any"
                      else "${rule.source.address} ${rule.source.wildcard}"
                    }
                  ''
              )
              acl.rules))
        )
        device.acl.standard))
      + mkSubTitle "Extended ACLs"
      + (builtins.concatStringsSep "\n" (map (
          acl:
            ''
              ip access-list extended ${
                if acl.name != null
                then acl.name
                else toString acl.id
              }
            ''
            + (builtins.concatStringsSep "\n" (map (
                rule:
                  lib.optionalString (rule.remark != null) "remark \"${rule.remark}\"\n"
                  + "${rule.action} ${rule.protocol} "
                  + "${
                    if rule.source == "any"
                    then "any"
                    else "${rule.source.address} ${rule.source.wildcard}"
                  } "
                  + "${
                    if rule.destination == "any"
                    then "any"
                    else "${rule.destination.address} ${rule.destination.wildcard}"
                  } "
                  + lib.optionalString (rule.op != null) "${rule.op} "
                  + lib.optionalString rule.log "log"
              )
              acl.rules))
        )
        device.acl.extended));
    renderGlobalIpv6Settings = device:
      mkSubTitle "RESET"
      + ''
      ''
      + mkSubTitle "Settings"
      + (
        if device.ipv6.routing
        then "ipv6 unicast-routing\n"
        else "no ipv6 unicast-routing\n"
      );
    renderGlobalIpSettings = device:
      mkSubTitle "RESET"
      + ''
        no ip domain name
        no ip default-gateway
        no ip name-server
        no ip domain lookup
      ''
      + mkSubTitle "Settings"
      + lib.optionalString (device.ip.domainName != null) "ip domain name ${device.ip.domainName}\n"
      + lib.optionalString (device.ip.defaultGateway != null) "ip default-gateway ${device.ip.defaultGateway}\n"
      + lib.optionalString device.ip.domainLookup.enable "ip domain lookup\n"
      + (
        if device.ip.routing
        then "ip routing\n"
        else "no ip routing\n"
      )
      + (
        if device.ip.http.server.enable
        then "ip http server\n"
        else "no ip http server\n"
      )
      + (
        if device.ip.http.secureServer.enable
        then "ip http secure-server\n"
        else "no ip http secure-server\n"
      );
    allPortChannels = interfaces: lib.attrsets.filterAttrs (name: value: value.portChannel == true) interfaces;
  in
    mkSubTitle "Pre config"
    + device.extraPreConfig
    +
    ''
    vtp mode transparent
    ''
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
    + mkTitle "ACLs"
    + renderACLs device
    + mkTitle "Global IPv4 Settings"
    + renderGlobalIpSettings device
    + mkTitle "Global IPv6 Settings"
    + renderGlobalIpv6Settings device
    + mkTitle "Interfaces"
    + mkSubTitle "RESET"
    + builtins.concatStringsSep "" (builtins.map (int: ''
        default interface ${int}
      '')
      device.deviceSpec.interfaces)
    + lib.concatStringsSep "\n" (map (value:
        renderInterface lib value.name value.value
    ) (builtins.sort (a: b: a.value.priority < b.value.priority) (map (name: { inherit name; value = device.interfaces.${name}; }) (builtins.attrNames device.interfaces))))
    + mkTitle "Routing"
    + mkSubTitle "Static Routes"
    + builtins.concatStringsSep "\n" (builtins.map (
        route:
          renderRoute lib route
      )
      device.routes)
    + lib.optionalString ((builtins.stringLength device.extraPostConfig) != 0) ''
      ${mkSubTitle "Post Config"}
      ${device.extraPostConfig}
    ''
    +
    mkSubTitle "Render Port channel fix EEM Applet"
    +
    renderPCEEM (allPortChannels device.interfaces)
    +
    mkSubTitle "Render Key generators EEM Applets"
    +
    builtins.concatStringsSep "\n" (lib.lists.imap0 (idx: key: renderKeyEEM idx key) device.keys)
    +
    ''
    end
    '';
}

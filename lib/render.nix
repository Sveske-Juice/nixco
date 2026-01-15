let
  renderSwitchport = lib: value: ''
    switchport mode ${value.switchport.mode}
  '' +
    lib.optionalString (!value.switchport.negotiate) "switchport nonegotiate\n"
    +
    lib.optionalString (value.switchport.mode == "access")
      "switchport access vlan ${toString value.switchport.vlan}\n"
    +
    lib.optionalString (value.switchport.mode == "trunk")
      ''
      switchport trunk native vlan ${toString value.switchport.trunk.nativeVLAN}
      switchport trunk allowed vlan ${value.switchport.trunk.allowed}
      ''
    +
    lib.optionalString (value.switchport.portSecurity != null) (
      ''
      switchport port-security
      switchport port-security maximum ${toString value.switchport.portSecurity.maximum}
      switchport port-security violation ${value.switchport.portSecurity.violation}
      ''
      +
      lib.optionalString ((builtins.length value.switchport.portSecurity.secureMacAddresses) != 0) (
        builtins.concatStringsSep "\n" (map (addr: "switchport port-security mac-address ${addr}") value.switchport.portSecurity.secureMacAddresses))
      +
      lib.optionalString (value.switchport.portSecurity.stickyMac)
        "switchport port-security mac-address sticky\n"
    )
    ;
  renderInterface = lib: ifname: value:
    mkSubTitle "Interface ${ifname}"
    +
    (if isRange ifname then
    "interface range ${ifname}\n"
    else
      "interface ${ifname}\n")
    +
    lib.optionalString (value.description != null) "description \"${value.description}\"\n"
    +
    lib.optionalString (!value.shutdown) "no shutdown\n"
    +
    (if value.switchport != null then renderSwitchport lib value else "")
    +
    lib.optionalString (value.ipAddress != null && value.ipAddress == "dhcp") "ip address dhcp\n"
    +
    lib.optionalString (value.ipAddress != null && builtins.isAttrs value.ipAddress) "ip address ${value.ipAddress.address} ${value.ipAddress.subnetmask}\n"
    +
    lib.optionalString (value.ipv6LinkLocal != null) "ipv6 address ${value.ipv6LinkLocal} link-local\n"
    +
    builtins.concatStringsSep "" (builtins.map (addr:
    "ipv6 address ${addr}\n"
    ) value.ipv6Addresses)
    +
    lib.optionalString (value.channelGroup != null) "channel-group ${toString value.channelGroup.groupNumber} mode ${value.channelGroup.mode}\n"
  ;
  mkSubTitle = title: ''!==== ${title} ====!
  '';
  mkTitle = title: ''
    ! +----------------------------+
    ! ${title}
    ! +----------------------------+
  '';
  isRange = key:
    builtins.match ".*[-,].*" key != null;
in {
  render = {lib, ...}: device: ''
    ! Config: ${builtins.toJSON device}

    configure terminal
  ''
  +
  lib.optionalString (device.hostname != null) "hostname ${device.hostname}\n"
  +
  mkTitle "VLANs"
  +
  (builtins.concatStringsSep "" (builtins.map (vlan:
  ''
    vlan ${toString vlan.id}
    name ${vlan.name}
  '') device.vlans))
  +
  lib.optionalString ((builtins.length device.vlans) != 0) "exit\n"
  +
  mkTitle "Interfaces"
  +
  mkSubTitle "RESET"
  +
  builtins.concatStringsSep "" (builtins.map (int: ''
    default interface ${int}
  '') device.deviceSpec.interfaces)
  +
  lib.concatMapAttrsStringSep "\n" (ifname: value:
      renderInterface lib ifname value
    ) device.interfaces
  ;
}

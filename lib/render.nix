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

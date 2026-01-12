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
    renderSwitchport lib value
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
    ! Device ${device.name}

    ! Config: ${builtins.toJSON device}
  '' +
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

let
  defaultInterface = device: import ../modules/default-interface.nix device;
  defaultInterfaces = device: lib: lib.genAttrs device.deviceSpec.interfaces (_: (defaultInterface device));
  mergedInterfaces = device: lib: (defaultInterfaces device lib) // device.interfaces;
  renderSwitchport = lib: value: ''
    switchport mode ${value.switchport.mode}
  '' +
    lib.optionalString (!value.switchport.negotiate) "switchport nonegotiate"
    +
    lib.optionalString (value.switchport.mode == "access")
      "switchport access vlan ${toString value.switchport.vlan}"
    +
    lib.optionalString (value.switchport.mode == "trunk")
      ''
      switchport trunk native vlan ${toString value.switchport.trunk.nativeVLAN}
      switchport trunk allowed vlan ${value.switchport.trunk.allowed}
      ''
    ;
  renderInterface = lib: ifname: value: ''
    ${mkSubTitle "Interface ${ifname}"}
    default interface ${ifname}
    interface ${ifname}
    '' +
    lib.optionalString (value.description != null) "description \"${value.description}\""
    +
    lib.optionalString (!value.shutdown) "no shutdown"
    +
    renderSwitchport lib value
  ;
  mkSubTitle = title: ''!==== ${title} ====!'';
  mkTitle = title: ''
    ! +----------------------------+
    ! ${title}
    ! +----------------------------+
  '';
in {
  render = {lib, ...}: device: ''
    ${builtins.toJSON (mergedInterfaces device lib)}
    ! Device ${device.name}

    ! Config: ${builtins.toJSON device}

    ${mkTitle "Interfaces"}
    ${let
      mergedIfs = builtins.trace (mergedInterfaces device lib) (mergedInterfaces device lib);
      in builtins.concatStringsSep "\n"
      (builtins.map
        (int:
            renderInterface lib int mergedIfs."${int}"
        )
        device.deviceSpec.interfaces)}
  '';
}

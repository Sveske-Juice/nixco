let
  defaultInterface = device: import ../modules/default-interface.nix device;
  defaultInterfaces = device: lib: lib.genAttrs device.deviceSpec.interfaces (_: (defaultInterface device));
  mergedInterfaces = device: lib: (defaultInterfaces device lib) // device.interfaces;
  renderInterface = ifname: value: ''
    ! Interface ${ifname}
    ${ifname} ${value.description}
  '';
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
            renderInterface int mergedIfs."${int}"
        )
        device.deviceSpec.interfaces)}
  '';
}

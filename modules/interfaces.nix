{
  lib,
  config,
  ...
}: let
  interfaceType = lib.types.submodule (_: {
    options = {
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Link to LAN1";
        description = "Descroption for this interface";
      };
      shutdown = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
      };
      switchport = lib.mkOption {
        type = lib.types.bool;
        example = false; # Routed port (L3)
        description = ''
          Determines if this is a L2 or L3 interface.
          If switchport is false, then it's a routed
          interface (L3).
        '';
        default =
          if config.deviceSpec.deviceType == "switch"
          then false
          else if config.deviceSpec.deviceType == "router"
          then true
          else lib.asserts.assertMsg false "Unkown device type";
      };
      vlan = lib.mkOption {
        type = lib.types.int;
        default = 1;
        example = 99;
      };
    };
  });
in {
  options = {
    interfaces = lib.mkOption {
      type = lib.types.attrsOf interfaceType;
    };
  };
}

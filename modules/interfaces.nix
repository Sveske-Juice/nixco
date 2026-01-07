{
  lib,
  config,
  ...
}: let
  switchPortType = lib.types.submodule (_: {
    options = {
      mode = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [
          "access"
          "dynamic auto"
          "dynamic desirable"
          "trunk"
        ]);
        # Routers dont have switchports. Switches are default access
        default =
          if config.deviceSpec.deviceType == "switch"
          then "access"
          else null;
      };
    };
  });
  interfaceType = lib.types.submodule (_: {
    options = {
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Link to LAN1";
        description = "Description for this interface";
      };
      shutdown = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
      };
      switchport = lib.mkOption {
        type = switchPortType;
        default = {};
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

  config.assertions = [
    {
      assertion = !lib.lists.all (int: config.deviceSpec.deviceType == "router" && int.switchport.mode != null) (builtins.attrValues config.interfaces);
      message = ''
        Routers can not have switchport's
      '';
    }
    {
      assertion = lib.lists.all (int: builtins.elem int config.deviceSpec.interfaces) (builtins.attrNames config.interfaces);
      message = ''
        The interface(s):
        ${toString (builtins.filter (int: !builtins.elem int config.deviceSpec.interfaces) (builtins.attrNames config.interfaces))}
        Does not exist on ${config.deviceSpec.name}
        Make sure you have spelled the interface correctly as specified
        in the device specification.
      '';
    }
  ];
}

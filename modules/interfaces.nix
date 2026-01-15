{
  lib,
  config,
  ...
}: let
  portSecurityType = lib.types.submodule (_: {
    options = {
      # TODO: pt doesnt support static, absolute/inactivity ?
      aging = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Aging settings in minutes. Disabled if null (default)";
      };
      secureMacAddresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      stickyMac = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Whether to write learned MAC addresses to running-config";
      };
      maximum = lib.mkOption {
        type = lib.types.int;
        default = 1;
        example = 6;
        description = "The maximum number of different secure MAC addresses";
      };
      violation = lib.mkOption {
        type = lib.types.enum [ "shutdown" "restrict" "protected" ];
        default = "shutdown";
      };
    };
  });
  channelGroupType = lib.types.submodule (_: {
    options = {
      groupNumber = lib.mkOption {
        type = lib.types.int;
        description = "Channel group number. Range: 1-48";
        example = 1;
      };
      mode = lib.mkOption {
        type = lib.types.enum [ "auto" "desirable" "active" "passive" "on" ];
        description = ''
          auto: PAgP mode. Becomes active if remote is desirable
          desirable: PAgP mode. Becomes active if remote is auto or desirable
          passive: LACP mode. Like auto
          active: LACP mode. Like desirable
          on: Static on. Only active if remote end is also set to "on"
        '';
        example = "on";
      };
    };
  });
  ipAddrMaskType = lib.types.submodule (_: {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        example = "192.168.1.1";
      };
      subnetmask = lib.mkOption {
        type = lib.types.str;
        example = "255.255.255.0";
      };
    };
  });
  interfaceDefault = import ./default-interface.nix config;
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
        type = lib.types.nullOr switchPortType;
        default = null;
      };
      ipAddress = lib.mkOption {
        type = lib.types.nullOr (lib.types.either ipAddrMaskType (lib.types.enum [ "dhcp" ]));
        default = null;
        example = {
          address = "192.168.1.1";
          subnetmask = "255.255.255.224";
        };
      };
      ipv6LinkLocal = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "fe80::1/64";
      };
      ipv6Addresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
      channelGroup = lib.mkOption {
        type = lib.types.nullOr channelGroupType;
        description = "Port-Channel/EtherChannel setup";
        default = null;
      };
    };
  });
  switchPortType = lib.types.submodule (_: {
    options = {
      mode = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [
          "access"
          "dynamic auto" # DTP
          "dynamic desirable" # DTP
          "trunk"
        ]);
        # Routers dont have switchports. Switches are default access
        default = interfaceDefault.switchport.mode;
      };
      negotiate = lib.mkOption {
        type = lib.types.bool;
        default = interfaceDefault.switchport.negotiate;
        description = "Enable Cisco Dynamic Trunking Protocol (DTP)";
      };
      vlan = lib.mkOption {
        type = lib.types.int;
        default = interfaceDefault.switchport.vlan;
        description = ''
          The VLAN ID of the VLAN when this port is in access mode.
        '';
      };
      trunk = lib.mkOption {
        type = lib.types.submodule (_: {
          options = {
            nativeVLAN = lib.mkOption {
              type = lib.types.int;
              default = interfaceDefault.switchport.trunk.nativeVLAN;
              description = ''
                native VLAN when interface is in trunking mode.
              '';
            };
            allowed = lib.mkOption {
              type = lib.types.str;
              default = interfaceDefault.switchport.trunk.allowed;
              description = ''
                VLANs allowed on this trunk interface. Can be a single VLAN "x"
                or a list of ranges: "a-b[, c-d, ...]", fx: 1-6, 99-200
              '';
            };
          };
        });
        default = {};
      };
      portSecurity = lib.mkOption {
        type = lib.types.nullOr portSecurityType;
        default = null;
      };
      # TODO:
      # - priority
      # - protected
      # - voice
    };
  });
in {
  options = {
    interfaces = lib.mkOption {
      type = lib.types.attrsOf interfaceType;
      default = {};
    };
  };

  config.assertions = [
    {
      assertion = !lib.lists.all (int: int.switchport.mode == "access" && int.switchport.negotiate) (builtins.attrValues config.interfaces);
      message = ''
        You must disable negotiation when using access switchport mode.
      '';
    }
    {
      assertion = !lib.lists.all (int: config.deviceSpec.deviceType == "router" && int.switchport.mode != null) (builtins.attrValues config.interfaces);
      message = ''
        Routers can not have switchport's
      '';
    }
    {
      # TODO: impl
      # assertion = lib.lists.all (int: int.switchport.portSecurity != null && int.switchport.mode != "access") (builtins.attrValues config.interfaces);
      # message = ''
      #   Port Security can only be configured on access switchports
      # '';
    }
  ];
}

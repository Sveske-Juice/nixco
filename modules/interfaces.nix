{
  lib,
  config,
  ...
}: let
  types = import ../lib/types.nix {inherit lib;};
  ipv6DHCPType = lib.types.submodule (_: {
    options = {
      relay = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            destination = lib.mkOption {
              type = lib.types.str;
              description = "Destination DHCPv6 Server to relay to";
            };
            interface = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional: The egress interface to get to the DHCPv6 server";
            };
          };
        }));
        default = null;
      };
    };
  });
  portSecurityType = lib.types.submodule (_: {
    options = {
      aging = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            time = lib.mkOption {
              type = lib.types.int;
            };
            static = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            type = lib.mkOption {
              type = lib.types.enum ["absolute" "inactivity"];
              default = "absolute";
            };
          };
        }));
        default = null; # disabled
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
        type = lib.types.enum ["shutdown" "restrict" "protected"];
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
        type = lib.types.enum ["auto" "desirable" "active" "passive" "on"];
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
      encapsulation = lib.mkOption {
        description = "802.1Q encapsulation";
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            vlanId = lib.mkOption {
              type = lib.types.int;
            };
          };
        }));
        default = null;
      };
      accessGroup = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            name = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            id = lib.mkOption {
              type = lib.types.nullOr (lib.types.ints.between 1 2699);
              default = null;
            };
            interface = lib.mkOption {
              type = lib.types.enum ["in" "out"];
            };
          };
        }));
        default = null;
      };
      channelGroup = lib.mkOption {
        type = lib.types.nullOr channelGroupType;
        description = "Port-Channel/EtherChannel setup";
        default = null;
      };
      ip = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            address = lib.mkOption {
              type = lib.types.nullOr (lib.types.either types.ipAddrMaskType (lib.types.enum ["dhcp"]));
              default = null;
              example = {
                address = "192.168.1.1";
                subnetmask = "255.255.255.224";
              };
            };
            ipHelper = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        }));
        default = null;
        description = "IPv4 settings for this interface";
      };
      ipv6 = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            linkLocal = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "fe80::1/64";
              description = "LLA Address of this interface";
            };
            addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
            };
            dhcp = lib.mkOption {
              type = lib.types.nullOr ipv6DHCPType;
              default = null;
            };
          };
        }));
        default = null;
        description = "IPv6 settings for this interface";
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
        default =
          if config.deviceSpec.deviceType == "switch"
          then "dynamic auto"
          else null;
      };
      negotiate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Cisco Dynamic Trunking Protocol (DTP)";
      };
      vlan = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = ''
          The VLAN ID of the VLAN when this port is in access mode.
        '';
      };
      trunk = lib.mkOption {
        type = lib.types.submodule (_: {
          options = {
            nativeVLAN = lib.mkOption {
              type = lib.types.int;
              default = 1;
              description = ''
                native VLAN when interface is in trunking mode (default: 1).
              '';
            };
            allowed = lib.mkOption {
              type = lib.types.str;
              default = "1-1005";
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

  config.assertions = let
    forAllInterfaces = pred: lib.lists.all pred (builtins.attrValues config.interfaces);
  in [
    {
      assertion = forAllInterfaces (int:
        if int.switchport == null
        then true
        else if int.switchport.mode == "access" && int.switchport.negotiate
        then false
        else true);
      message = ''
        You must disable negotiation when using access switchport mode.
      '';
    }
    {
      assertion = forAllInterfaces (int:
        if config.deviceSpec.deviceType != "router"
        then true
        else int.switchport != null);
      message = ''
        Routers can not have switchport's
      '';
    }
    {
      assertion = forAllInterfaces (int:
        if int.switchport == null
        then true
        else if int.switchport.portSecurity == null
        then true
        else int.switchport.mode == "access");
      message = ''
        Port Security can only be configured on access switchports
      '';
    }
  ];
}

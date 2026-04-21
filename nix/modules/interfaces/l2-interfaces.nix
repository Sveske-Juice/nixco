# L2 Specific interface options
{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.l2-interface = {
    options = {
      switchport = lib.mkOption {
        description = "Switchport settings";
        default = null;
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            enable = lib.mkOption {
              default = true;
              description = "Is this interface a switchport?";
              type = lib.types.bool;
            };
            mode = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [
                "access"
                "dynamic auto" # DTP
                "dynamic desirable" # DTP
                "trunk"
              ]);
              default = "dynamic auto";
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
              default = {};
              type = lib.types.submodule {
                options = {
                  nativeVLAN = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                    description = ''
                      native VLAN when interface is in trunking mode (default: 1).
                    '';
                  };
                  allowed = lib.mkOption {
                    type = lib.types.either (lib.types.listOf lib.types.int) lib.types.str;
                    default = "1-1005";
                    description = ''
                      VLANs allowed on this trunk interface. Can be a single VLAN "x"
                      or a list of ranges: "a-b[, c-d, ...]", fx: 1-6, 99-200
                    '';
                  };
                };
              };
            };
            # TODO:
            # - priority
            # - protected
            # - voice
            portSecurity = lib.mkOption {
              default = null;
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  aging = lib.mkOption {
                    type = lib.types.nullOr (lib.types.submodule {
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
                    });
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
            };
          };
        });
      };
      mac = lib.mkOption {
        default = {};
        type = lib.types.submodule {
          options = {
            accessGroup = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "MAC PACL name";
                  };
                  id = lib.mkOption {
                    type = lib.types.nullOr (lib.types.ints.between 1 2699);
                    default = null;
                    description = "MAC PACL id";
                  };
                  interface = lib.mkOption {
                    type = lib.types.enum ["in" "out"];
                  };
                };
              };
              default = {};
            };
          };
        };
      };
    };
  };
}

{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.l3-interface = {
    options = {
      encapsulation = lib.mkOption {
        description = "802.1Q encapsulation";
        type = lib.types.nullOr (lib.types.submodule (_: {
          options = {
            vlanId = lib.mkOption {
              type = lib.types.ints.between 1 4096;
            };
          };
        }));
        default = null;
      };
      ip = lib.mkOption {
        description = "ipv4 settings for interface";
        default = {};
        type = lib.types.submodule {
          options = {
            address = lib.mkOption {
              type = lib.types.nullOr (lib.types.either self.lib.types.ipv4Network (lib.types.enum ["dhcp"]));
              default = null;
              example = {
                addr = "192.168.1.1";
                netmask = "255.255.255.224";
              };
            };
            ipHelper = lib.mkOption {
              type = lib.types.nullOr self.lib.types.ipv4;
              default = null;
            };
            accessGroup = lib.mkOption {
              default = null;
              type = lib.types.nullOr (lib.types.submodule {
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
              });
            };
          };
        };
      };
      ipv6 = lib.mkOption {
        description = "ipv6 settings for interface";
        default = {};
        type = lib.types.submodule {
          options = {
            linkLocal = lib.mkOption {
              type = lib.types.nullOr self.lib.types.ipv6;
              default = null;
              example = "fe80::1/64";
              description = "LLA Address of this interface";
            };
            addresses = lib.mkOption {
              type = lib.types.listOf self.lib.types.ipv6;
              default = [];
            };
            dhcp = lib.mkOption {
              default = null;
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  relay = lib.mkOption {
                    type = lib.types.nullOr (lib.types.submodule {
                      options = {
                        destination = lib.mkOption {
                          type = self.lib.types.ipv6;
                          description = "Destination DHCPv6 Server to relay to";
                        };
                        interface = lib.mkOption {
                          type = lib.types.nullOr lib.types.str;
                          default = null;
                          description = "Optional: The egress interface to get to the DHCPv6 server";
                        };
                      };
                    });
                    default = null;
                  };
                };
              });
            };
          };
        };
      };
    };
  };
}


{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.acl = {
    options = {
      acl = lib.mkOption {
        default = {};
        type = lib.types.submodule (_: {
          options.standard = lib.mkOption {
            default = [];
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The access-list-name";
                };
                id = lib.mkOption {
                  type = lib.types.nullOr (lib.types.ints.between 1 99);
                  default = null;
                  description = "The access-list-number";
                };
                rules = lib.mkOption {
                  default = [];
                  type = lib.types.listOf (lib.types.submodule {
                    options = {
                      remark = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Optional remark for this rule entry";
                      };
                      action = lib.mkOption {
                        type = lib.types.enum ["deny" "permit"];
                      };
                      log = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                      };
                      source = lib.mkOption {
                        type = lib.types.oneOf [
                          (lib.types.enum [ "any" ])
                          self.lib.types.ipv4Network
                          self.lib.types.ipv6Network
                        ];
                      };
                    };
                  });
                };
              };
            });
          };
          options.extended = lib.mkOption {
            default = [];
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The access-list-name";
                };
                id = lib.mkOption {
                  type = lib.types.nullOr (lib.types.ints.between 100 2699);
                  default = null;
                  description = "The access-list-number";
                };
                rules = lib.mkOption {
                  default = [];
                  type = lib.types.listOf (lib.types.submodule {
                    options = {
                      remark = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Optional remark for this rule entry";
                      };
                      action = lib.mkOption {
                        type = lib.types.enum ["deny" "permit"];
                      };
                      log = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                      };
                      protocol = lib.mkOption {
                        type = lib.types.str;
                        example = "ip";
                      };
                      op = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "The operator and argument to use";
                        example = "range 10 20";
                      };
                      source = lib.mkOption {
                        type = lib.types.oneOf [
                          (lib.types.enum [ "any" ])
                          self.lib.types.ipv4Network
                          self.lib.types.ipv6Network
                        ];
                      };
                      destination = lib.mkOption {
                        type = lib.types.oneOf [
                          (lib.types.enum [ "any" ])
                          self.lib.types.ipv4Network
                          self.lib.types.ipv6Network
                        ];
                      };
                    };
                  });
                };
              };
            });
          };
        });
      };
    };
  };
}

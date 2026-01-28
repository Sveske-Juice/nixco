{lib, ...}: let
  types = import ../lib/types.nix {inherit lib; };
  standardType = lib.types.submodule (_: {
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
        type = lib.types.listOf (lib.types.submodule (_: {
          options = {
            remark = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional remark for this rule entry";
            };
            action = lib.mkOption {
              type = lib.types.enum [ "deny" "permit" ];
            };
            log = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            source = lib.mkOption {
              type = lib.types.either (lib.types.enum [ "any" ]) types.ipAddrWildcardType;
            };
          };
        }));
        default = [];
      };
    };
  });
  extendedType = lib.types.submodule (_: {
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
        type = lib.types.listOf (lib.types.submodule (_: {
          options = {
            remark = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional remark for this rule entry";
            };
            action = lib.mkOption {
              type = lib.types.enum [ "deny" "permit" ];
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
              type = lib.types.either (lib.types.enum [ "any" ]) types.ipAddrWildcardType;
            };
            destination = lib.mkOption {
              type = lib.types.either (lib.types.enum [ "any" ]) types.ipAddrWildcardType;
            };
          };
        }));
        default = [];
      };
    };
  });
in {
  options.acl = lib.mkOption {
    default = {};
    type = lib.types.submodule (_: {
      options.standard = lib.mkOption {
        type = lib.types.listOf standardType;
        default = [];
      };
      options.extended = lib.mkOption {
        type = lib.types.listOf extendedType;
        default = [];
      };
    });
  };
}

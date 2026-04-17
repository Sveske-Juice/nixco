# L2 Specific interface options
{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.l2-interface = lib.mkOption {
    options = {
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

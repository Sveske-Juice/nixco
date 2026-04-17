{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.vlans = {
    options = {
      vlans = lib.mkOption {
        default = [];
        type = lib.types.listOf (lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.ints.between 1 4096;
              example = 999;
            };
            name = lib.mkOption {
              type = lib.types.str;
              example = "VLAN10";
            };
          };
        });
      };
    };
  };
}


{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.assertions = {
    options.assertions = lib.mkOption {
      default = [];
      description = ''
        List of assertions for this device. They must all return true inorder
        to render the device.
      '';
      type = lib.types.listOf (lib.types.submodule {
        options = {
          assertion = lib.mkOption {
            type = lib.types.bool;
          };
          message = lib.mkOption {
            type = lib.types.lines;
            default = "Failed assertion";
          };
        };
      });
    };
  };
}

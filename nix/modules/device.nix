{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.device = {
    options.devices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.hostname = lib.mkOption {
          type = lib.types.str;
        };
      });
      default = {};
    };
  };
}

{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.device = {
    options.hostname = lib.mkOption {
      type = lib.types.str;
    };
    options.deviceSpec = lib.mkOption {
      type = lib.types.attrs;
    };
  };
}

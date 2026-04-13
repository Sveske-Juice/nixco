{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  options.flake.nixcoModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.deferredModule;
    default = {};
  };
}

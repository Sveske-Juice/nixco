{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  options.flake.lib = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Custom library functions";
  };
}

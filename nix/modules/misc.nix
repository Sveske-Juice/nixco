{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.misc = {
    options = {
      extraPreConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra configuration prepended before the main config";
      };
      extraPostConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Exstra configuration appended at end of configuration";
      };
      comments = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to include QoL comments in the rendered config";
      };
    };
  };
}

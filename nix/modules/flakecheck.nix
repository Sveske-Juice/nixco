{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.other = {
    options.flakeCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Automatically add all nixcoConfigurations to `checks.<system>`.
      '';
    };
  };
}

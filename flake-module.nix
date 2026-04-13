{ self }:
{ config, lib, ... }: {
  options.nixco = lib.mkOption {
    type = lib.types.submodule {
      imports = [
        self.nixcoModules.device
      ];
      options.flakeCheck = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Automatically add all nixcoConfigurations to.`checks.<system>`.
        '';
      };
    };
    default = {};
  };

  config = {
    flake.nixcoConfigurations = let
      evaluatedDevices = self.lib.eval [ config.nixco ];
    in
      self.lib.renderAll evaluatedDevices.config.devices;

    perSystem = { pkgs, ... }: let
      devicePackages = lib.mapAttrs (name: text:
          pkgs.writeText "${name}.ios" text
        ) config.flake.nixcoConfigurations;
    in {
      packages = devicePackages;
      checks = lib.mkIf config.nixco.flakeCheck devicePackages;
    };
  };
}

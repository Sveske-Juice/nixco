{self}: {
  config,
  lib,
  ...
}: {
  options.nixco = lib.mkOption {
    type = lib.types.submodule {
      options = {
        devices = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            imports = [
              self.nixcoModules.misc
              self.nixcoModules.banner
              self.nixcoModules.device
              self.nixcoModules.ip
              self.nixcoModules.ipv6
              self.nixcoModules.interfaces
            ];
          });
          default = {};
        };
        flakeCheck = lib.mkOption {
          type = lib.types.bool;
          default = true;
          example = false;
          description = ''
            Automatically add all nixcoConfigurations to.`checks.<system>`.
          '';
        };
      };
    };
    default = {};
  };

  config = {
    flake.nixcoConfigurations = self.lib.renderAll config.nixco.devices;

    perSystem = {pkgs, ...}: let
      devicePackages =
        lib.mapAttrs (
          name: text:
            pkgs.writeText "${name}.ios" text
        )
        config.flake.nixcoConfigurations;
    in {
      packages = devicePackages;
      checks = lib.mkIf config.nixco.flakeCheck devicePackages;
    };
  };
}

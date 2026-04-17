{self, inputs, ...}: {
  flake.flakeModules.default = self.flakeModules.nixco;
  flake.flakeModules.nixco = {config, lib, ...}: {
    options.nixco = lib.mkOption {
      type = lib.types.submodule {
        options = {
          devices = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              imports = [
                self.nixcoModules.misc
                self.nixcoModules.banner
                self.nixcoModules.device
                self.nixcoModules.vlans
                self.nixcoModules.ip
                self.nixcoModules.ipv6
                self.nixcoModules.interfaces
                self.nixcoModules.eem
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
          deviceSpecs = lib.mkOption {
            default = {};
            description = "This device's hardware specification";
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of device";
                };
                interfaces = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [];
                  description = "The interfaces this device have";
                };
              };
            });
          };
        };
      };
      default = {};
    };

    config = {
      flake.nixcoConfigurations = self.lib.renderAll config.nixco.devices;
      # Builtin device specs
      nixco.deviceSpecs = lib.foldl' lib.mergeAttrs {}
        (lib.mapAttrsToList
          (fname: _: import (../lib/_devices + "/${fname}"))
          (builtins.readDir ../lib/_devices)
        );
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
  };
}

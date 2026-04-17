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
  nixco.deviceSpecs."C9200L-24P-4G" = {
    name = "C9200L-24P-4G";
    interfaces = [
      "GigabitEthernet0/0"
      "GigabitEthernet1/0/1"
      "GigabitEthernet1/0/2"
      "GigabitEthernet1/0/3"
      "GigabitEthernet1/0/4"
      "GigabitEthernet1/0/5"
      "GigabitEthernet1/0/6"
      "GigabitEthernet1/0/7"
      "GigabitEthernet1/0/8"
      "GigabitEthernet1/0/9"
      "GigabitEthernet1/0/10"
      "GigabitEthernet1/0/11"
      "GigabitEthernet1/0/12"
      "GigabitEthernet1/0/13"
      "GigabitEthernet1/0/14"
      "GigabitEthernet1/0/15"
      "GigabitEthernet1/0/16"
      "GigabitEthernet1/0/17"
      "GigabitEthernet1/0/18"
      "GigabitEthernet1/0/19"
      "GigabitEthernet1/0/20"
      "GigabitEthernet1/0/21"
      "GigabitEthernet1/0/22"
      "GigabitEthernet1/0/23"
      "GigabitEthernet1/0/24"
      "GigabitEthernet1/1/1"
      "GigabitEthernet1/1/2"
      "GigabitEthernet1/1/3"
      "GigabitEthernet1/1/4"
    ];
  };

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

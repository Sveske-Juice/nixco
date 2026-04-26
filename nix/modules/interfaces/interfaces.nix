# General interface options
{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.interfaces = {config, ...}: {
    options = {
      interfaces = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule [
          self.nixcoModules.interface-general
          self.nixcoModules.l2-interface
          self.nixcoModules.l3-interface
        ]);
        default = {};
        description = "Interface configuration";
      };
    };

    config.assertions = [
      {
        assertion = lib.lists.all (int: config.deviceSpec.deviceType == "router" -> int.switchport == null) (builtins.attrValues config.interfaces);
        message = ''
          It is not allowed to configure switchport settings on router interfaces.
        '';
      }
    ];
  };

  flake.nixcoModules.interface-general = {
    options = {
      priority = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = ''
          The order which interfaces gets rendered.
          The higher the priority the later it will be rendered.
          0 will be rendered first
        '';
      };
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Interface description";
      };
      range = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Does this value configure a range of interfaces?";
      };
      portChannel = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Required to be true for port channels, so we can add this interface for the delayed port channel EEM applet";
      };
      shutdown = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
      };
      channelGroup = lib.mkOption {
        description = "Port/Ether-channels";
        default = null;
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            groupNumber = lib.mkOption {
              type = lib.types.int;
              description = "Channel group number. Range: 1-48";
              example = 1;
            };
            mode = lib.mkOption {
              type = lib.types.enum ["auto" "desirable" "active" "passive" "on"];
              description = ''
                auto: PAgP mode. Becomes active if remote is desirable
                desirable: PAgP mode. Becomes active if remote is auto or desirable
                passive: LACP mode. Like auto
                active: LACP mode. Like desirable
                on: Static on. Only active if remote end is also set to "on"
              '';
              example = "on";
            };
          };
        });
      };
      extraPostConfig = lib.mkOption {
        description = "Extra Config added to end of interface config (before shutdown)";
        default = "";
        type = lib.types.lines;
      };
    };
  };
}

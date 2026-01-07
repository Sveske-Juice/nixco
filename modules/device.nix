{
  lib,
  config,
  ...
}: let
  models = import ../lib/models;
  deviceSpecType = lib.types.submodule (_: {
    options = {
      deviceType = lib.mkOption {
        type = lib.types.enum ["switch" "router"];
        description = ''
          The device's type determines some of the default
          settings for a device. For example interfaces
          on routers are routed interfaces by default,
          while switchports on switches.
        '';
      };
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "The interfaces this device contains";
      };
    };
  });
in {
  options = {
    device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    deviceSpec = lib.mkOption {
      type = lib.types.nullOr deviceSpecType;
      default =
        if (config.device == null)
        then null
        else models."${config.device}";
    };
  };

  config.assertions = [
    {
      assertion = (config.device != null) || (config.deviceSpec != null);
      message = ''
        You must either provide a pre-defined device or
        specify a custom device specification.

        You must set:
        `options.device` or `options.deviceSpec`
      '';
    }
  ];
}

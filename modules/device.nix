{
  lib,
  config,
  ...
}: let
  models = import ../lib/models;
  deviceSpecType = lib.types.submodule (_: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "custom device";
        example = "C9200L-24P-4G";
        description = "Model name of the device";
      };
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
    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      example = "SW1";
    };
    ip = lib.mkOption {
      type = lib.types.submodule (_: {
        options = {
          domainName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          defaultGateway = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "ipv4 host address of DGW";
            default = null;
          };
          nameServers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of ipv4 and ipv6 name servers to use. Max 6 for each ip version";
          };
          domainLookup = lib.mkOption {
            type = lib.types.submodule (_: {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                # TODO: nsap, recursive, source-interface, vrf
              };
            });
            default = {};
          };
        };
      });
      default = {};
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

{lib, ...}: let
  httpOpts = lib.types.submodule (_: {
    options.secureServer = lib.mkOption {
      description = "HTTPS configuration server";
      default = {};
      type = lib.types.submodule (_: {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          options.server = lib.mkOption {
            description = "HTTP configuration server";
            default = {};
            type = lib.types.submodule (_: {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
                # TODO: other settings
              };
            });
          };
          # TODO: other settings
        };
      });
    };
  });
  ipOpts = lib.types.submodule (_: {
    options = {
      routing = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
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
      http = lib.mkOption {
        type = httpOpts;
        default = {};
      };
    };
  });
in {
  options = {
    ip = lib.mkOption {
      type = ipOpts;
      default = {};
    };
  };
}

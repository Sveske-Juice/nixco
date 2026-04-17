{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.ip = {
    options.ip = lib.mkOption {
      description = "Global IP Configuration";
      default = {};
      type = lib.types.submodule {
        imports = [
          self.nixcoModules.http
        ];
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
            type = lib.types.nullOr self.lib.types.ipv4;
            description = "ipv4 host address of DGW";
            default = null;
          };
          nameServers = lib.mkOption {
            type = lib.types.listOf (lib.types.either self.lib.types.ipv4 self.lib.types.ipv6);
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
      };
    };
  };
}

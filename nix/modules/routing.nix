{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.routing = {
    options = {
      routes = lib.mkOption {
        default = [];
        type = lib.types.listOf (lib.types.submodule {
          options = {
            ipv6 = lib.mkEnableOption {
              default = false;
              description = "Whether this is a ipv6 or ipv4 route";
            };
            destination = lib.mkOption {
              type = lib.types.either self.lib.types.ipv4Network self.lib.types.ipv6Network;
            };
            nextHop = lib.mkOption {
              type = lib.types.nullOr lib.types.either self.lib.types.ipv4 self.lib.types.ipv6;
              default = null;
              description = "Address of the next hop";
            };
            exitInterface = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "The directly-connected interface to forward traffic to";
            };
            distance = lib.mkOption {
              type = lib.types.int;
              description = "The Administrative Distance (AD) for this route. Static routes are by default 1";
              default = 1;
            };
            # TODO:
            # multicast
            # name
            # permanent
            # tack
            # track
          };
        });
      };
    };
  };
}

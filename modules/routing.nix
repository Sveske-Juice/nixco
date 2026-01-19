{
  lib,
  nixcoLib,
  ...
}: let
  ipRouteType = lib.types.submodule (_: {
    options = {
      ipv6 = lib.mkEnableOption {
        default = false;
        description = "Whether this is a ipv6 or ipv4 route";
      };
      destination = lib.mkOption {
        type = lib.types.either nixcoLib.types.ipAddrMaskType lib.types.str; # ipv4 (addr + mask) | ipv6 (addr + prefix)
      };
      nextHop = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
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
in {
  options = {
    routes = lib.mkOption {
      type = lib.types.listOf ipRouteType;
      default = [];
    };
  };
}

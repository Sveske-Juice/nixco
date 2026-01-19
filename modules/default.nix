{lib, ...}: {
  imports = [
    ./assertions.nix
    ./device.nix
    ./interfaces.nix
    ./routing.nix
    ./vlan.nix
  ];
  options = {
    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      example = "SW1";
    };
    iosVersion = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0";
    };
  };
}

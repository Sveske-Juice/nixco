{lib, ...}: {
  imports = [
    ./assertions.nix
    ./banner.nix
    ./device.nix
    ./interfaces.nix
    ./routing.nix
    ./vlan.nix
  ];
  options = {
    iosVersion = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0";
    };
  };
}

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
    comments = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to include nice to have comments in rendered config";
    };
    iosVersion = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0";
    };
  };
}

{lib, ...}: {
  imports = [
    ./assertions.nix
    ./device.nix
    ./interfaces.nix
  ];
  options = {
    name = lib.mkOption {type = lib.types.str;};
    iosVersion = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0";
    };
  };
}

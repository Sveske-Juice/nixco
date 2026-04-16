{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.ipv6 = {
    options = {
      ipv6 = lib.mkOption {
        description = "Global IPv6 Configuration";
        type = lib.types.submodule {
          options = {
            routing = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        };
      };
    };
  };
}

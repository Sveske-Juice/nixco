{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.ipv6 = {
    options = {
      ipv6 = lib.mkOption {
        description = "Global IPv6 Configuration";
        default = {};
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

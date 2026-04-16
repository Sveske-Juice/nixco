{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.ip.options.http = lib.mkOption {
    description = "HTTP Settings";
    type = lib.types.submodule {
      options = {
        server = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            # TODO: opts
          };
        };
        secureServer = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            # TODO: opts
          };
        };
        # TODO: opts
      };
    };
  };
}

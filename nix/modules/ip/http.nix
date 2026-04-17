{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.http = {
    options = {
      http = lib.mkOption {
        description = "HTTP Settings";
        default = {};
        type = lib.types.submodule {
          options = {
            server = lib.mkOption {
              default = {};
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };
                  # TODO: opts
                };
              };
            };
            secureServer = lib.mkOption {
              default = {};
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };
                  # TODO: opts
                };
              };
            };
          };
        };
      };
    };
  };
}

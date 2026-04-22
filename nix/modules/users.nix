{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.users = {
    options.enable = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          algorithmType = lib.mkOption {
            default = "scrypt";
            type = lib.types.enum ["md5" "sha256" "scrypt"];
          };
          secret = lib.mkOption {
            type = lib.types.str;
          };
        };
      });
    };
    options.username = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          description = lib.mkOption {
            default = null;
            type = lib.types.nullOr lib.types.str;
          };
          privilege = lib.mkOption {
            default = 15;
            type = lib.types.ints.between 0 15;
          };
          algorithmType = lib.mkOption {
            default = "scrypt";
            type = lib.types.enum ["sha256" "scrypt"];
          };
          secret = lib.mkOption {
            type = lib.types.str;
          };
          nopassword = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Allow login without password";
          };
        };
      });
    };
  };
}

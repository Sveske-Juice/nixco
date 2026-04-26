{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.keys = {config, ...}: {
    options.keyChains = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          description = lib.mkOption {
            description = "Description for the key chain";
            default = null;
            type = lib.types.nullOr lib.types.str;
          };
          keys = lib.mkOption {
            default = {};
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                cryptographicAlgorithm = lib.mkOption {
                  type = lib.types.enum ["md5" "hmac-sha-1" "hmac-sha-384" "hmac-sha-512"];
                };
                keyString = lib.mkOption {
                  type = lib.types.str;
                };
                sendLifetime = lib.mkOption {
                  default = null;
                  type = lib.types.nullOr lib.types.str;
                };
              };
            });
          };
        };
      });
    };
    options.keys = lib.mkOption {
      default = [];
      type = lib.types.listOf (lib.types.submodule {
        options = {
          type = lib.mkOption {
            type = lib.types.enum ["ec" "rsa"];
          };
          rsaOpts = lib.mkOption {
            type = lib.types.submodule {
              options = {
                modulus = lib.mkOption {
                  type = lib.types.ints.between 512 4096;
                  default = 1024;
                };
                label = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The name for the key. Defaults to the domain name of the device";
                  default = null;
                };
              };
            };
          };
          ecOpts = lib.mkOption {
            type = lib.types.submodule {
              options = {
                keysize = lib.mkOption {
                  type = lib.types.enum [256 384 521];
                  default = 256;
                };
              };
            };
          };
        };
      });
    };

    config.assertions = [
      {
        assertion = lib.lists.all (key: key.type == "rsa" -> key.rsaOpts.label == null -> config.ip.domainName != null) config.keys;
        message = ''
          Key with no label specified but no domain name has been set.
          Either set a domain name with `ip.domainName` or set a custom label
          for the key.
        '';
      }
    ];
  };
}

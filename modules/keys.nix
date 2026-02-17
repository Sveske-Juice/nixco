{lib, ...}: let
  ecOpts = lib.types.submodule (_: {
    options = {
      keysize = lib.mkOption {
        type = lib.types.enum [ 256 384 521 ];
        default = 256;
      };
    };
  });
  rsaOpts = lib.types.submodule (_: {
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
  });
  keyType = lib.types.submodule (_: {
    options ={
      type = lib.mkOption {
        type = lib.types.enum [ "ec" "rsa" ];
      };
      rsaOpts = lib.mkOption {
        type = rsaOpts;
      };
      ecOpts = lib.mkOption {
        type = ecOpts;
      };
    };
  });
in {
  options = {
    keys = lib.mkOption {
      default = [];
      type = lib.types.listOf keyType;
    };
  };
}

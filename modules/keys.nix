{lib, config, ...}: let
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

  config.assertions = [
    {
      assertion = lib.lists.all (key:
        if key.type != "rsa"
        then true
        else if key.rsaOpts.label != null
        then true
        # If no label specified, domain name must be set
        else config.ip.domainName != null) config.keys;
      message = ''
        Key with no label specified but no domain name has been set.
        Either set a domain name with `ip.domainName` or set a custom label
        for the key.
      '';
    }
  ];
}

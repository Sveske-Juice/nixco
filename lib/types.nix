{lib}: {
  ipAddrMaskType = lib.types.submodule (_: {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        example = "192.168.1.1";
      };
      subnetmask = lib.mkOption {
        type = lib.types.str;
        example = "255.255.255.0";
      };
    };
  });
  ipAddrWildcardType = lib.types.submodule (_: {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        example = "192.168.1.1";
      };
      wildcard = lib.mkOption {
        type = lib.types.str;
        example = "0.0.0.255";
      };
    };
  });
}

{lib, ...}: {
  options = {
    ipv6 = lib.mkOption {
      default = {};
      type = lib.types.submodule (_: {
        options = {
          routing = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      });
    };
  };
}

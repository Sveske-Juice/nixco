{lib, ...}: {
  options.assertions = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        assertion = lib.mkOption {
          type = lib.types.bool;
        };
        message = lib.mkOption {
          type = lib.types.str;
        };
      };
    });
    default = [];
    internal = true;
    description = "List of module assertions";
  };
}

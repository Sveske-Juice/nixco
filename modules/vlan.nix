{lib, ...}: let
  vlanType = lib.types.submodule (_: {
    options = {
      id = lib.mkOption {
        type = lib.types.int;
        example = 999;
      };
      name = lib.mkOption {
        type = lib.types.str;
        example = "VLAN10";
      };
    };
  });
in {
  options = {
    vlans = lib.mkOption {
      type = lib.types.listOf vlanType;
      default = [];
    };
  };
}

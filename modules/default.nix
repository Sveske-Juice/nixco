{lib, ...}: let
  deviceType = lib.types.submodule (_: {
    imports = [
      ./banner.nix
      ./device.nix
      ./ip.nix
      ./ipv6.nix
      ./interfaces.nix
      ./acl.nix
      ./routing.nix
      ./vlan.nix
      ./assertions.nix
      ./keys.nix
    ];
    options = {
      extraPreConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra configuration prepended before the main config";
      };
      extraPostConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Exstra configuration appended at end of configuration";
      };
      comments = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to include nice to have comments in rendered config";
      };
      iosVersion = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0";
      };
    };
  });
in {
  imports = [
  ];
  options = {
    devices = lib.mkOption {
      type = lib.types.attrsOf deviceType;
      default = {};
    };
  };
}

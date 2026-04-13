{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.types = {
    ipv4Address = lib.mkOptionType {
      name = "ipAddress";
      description = "IPv4 Address";
      check = str: builtins.match "[0-9]{1,3}(\.[0-9]{1,3}){3}" str != null;
    };
  };
}

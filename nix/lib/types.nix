{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.types = {
    ipv4 = lib.mkOptionType {
      name = "ipv4Address";
      description = "IPv4 Address";
      check = str: builtins.match "[0-9]{1,3}(\.[0-9]{1,3}){3}" str != null;
    };
    # FIXME: update this
    ipv6 = lib.mkOptionType {
      name = "ipv6Address";
      description = "IPv6 Address";
      check = str: builtins.match "[0-9]{1,3}(\.[0-9]{1,3}){3}" str != null;
    };
  };
}

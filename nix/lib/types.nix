{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
  isValidipv4 = str: builtins.match "[0-9]{1,3}(\.[0-9]{1,3}){3}" str != null;
  # TODO: 
  isValidNetmask = mask: true;
in {
  flake.lib.types = {
    ipv4 = lib.mkOptionType {
      name = "ipv4Address";
      description = "IPv4 Address";
      check = isValidipv4;
    };

    ipv4Network = lib.mkOptionType {
      name = "ipv4Network";
      description = "IPV4 Network";
      check = v:
        lib.isAttrs v
        && v ? addr
        && v ? netmask
        && isValidipv4 v.addr
        && isValidNetmask v.netmask;
    };

    ipv6 = lib.mkOptionType {
      name = "ipv6Address";
      description = "IPv6 Address";
      # FIXME: update this
      check = isValidipv4;
    };
  };
}

{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
  isValidipv4 = str: builtins.match "[0-9]{1,3}(\.[0-9]{1,3}){3}" str != null;
  # i made AI cook this one chat. if its wrong gg, i aint spending my free time
  # on regex.
  isValidipv6 = str: let
    # Strip optional prefix length e.g. 2001:db8::1/64
    addr = builtins.head (lib.splitString "/" str);
    # Must contain at least one colon
    hasColon = builtins.match ".*:.*" addr != null;
    # Only hex digits and colons allowed
    validChars = builtins.match "[0-9a-fA-F:]+" addr != null;
    # At most one "::" (splitString gives length 2 if one "::" present)
    atMostOneCompress = builtins.length (lib.splitString "::" addr) <= 2;
    # Each group (split by single colon, ignoring empty from ::) is max 4 hex chars
    groups = builtins.filter (g: g != "") (lib.splitString ":" addr);
    validGroups = builtins.all (g: builtins.match "[0-9a-fA-F]{1,4}" g != null) groups;
  in
    hasColon && validChars && atMostOneCompress && validGroups;
  # TODO:
  isValidNetmask = _mask: true;
in {
  flake.lib.netmask2Wildcard = netmask: let
    octets = lib.splitString "." netmask;
    invertOctet = o: toString (255 - lib.toInt o);
  in
    lib.concatStringsSep "." (map invertOctet octets);
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
      check = isValidipv6;
    };
  };
}

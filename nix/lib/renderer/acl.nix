{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.renderACLs = device:
    self.lib.mkSubTitle device "RESET"
    + ''
      ! ACLs cant be reset automaticaly, to reset you must use a strategy which reloads the device
    ''
    + self.lib.mkSubTitle device "Standard ACLs"
    + (builtins.concatStringsSep "\n" (map (
      acl:
      ''
        ip access-list standard ${
        if acl.name != null
          then acl.name
        else toString acl.id
      }
      ''
      + (builtins.concatStringsSep "\n" (map (
        rule:
        lib.optionalString (rule.remark != null) "remark \"${rule.remark}\"\n"
        + ''
          ${rule.action} ${
          if rule.source == "any"
            then "any"
          else "${rule.source.addr} ${self.lib.netmask2Wildcard rule.source.netmask}"
        }
        ''
      )
        acl.rules))
    )
      device.acl.standard))
    + self.lib.mkSubTitle device "Extended ACLs"
    + (builtins.concatStringsSep "\n" (map (
      acl:
      ''
        ip access-list extended ${
        if acl.name != null
          then acl.name
        else toString acl.id
      }
      ''
      + (builtins.concatStringsSep "\n" (map (
        rule:
        lib.optionalString (rule.remark != null) "remark \"${rule.remark}\"\n"
        + "${rule.action} ${rule.protocol} "
        + "${
        if rule.source == "any"
          then "any"
        else "${rule.source.addr} ${self.lib.netmask2Wildcard rule.source.netmask}"
      } "
        + "${
        if rule.destination == "any"
          then "any"
        else "${rule.destination.addr} ${self.lib.netmask2Wildcard rule.destination.netmask}"
      } "
        + lib.optionalString (rule.op != null) "${rule.op} "
        + lib.optionalString rule.log "log"
      )
        acl.rules))
        + "\n"
    )
      device.acl.extended));
}

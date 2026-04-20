{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.renderAll = devices:
    lib.mapAttrs (_: value:
      self.lib.render value)
    devices;
  flake.lib.render = device:
    self.lib.mkSubTitle device "Pre config"
    + device.extraPreConfig
    + ''
      vtp mode transparent
    ''
    + lib.optionalString (device.hostname != null) "hostname ${device.hostname}\n"
    + self.lib.mkTitle device "Banners"
    + ''
      banner motd #${device.banner.motd}#
      banner login #${device.banner.login}#
      banner config-save #${device.banner.configSave}#
      banner exec #${device.banner.exec}#
      banner incoming #${device.banner.incoming}#
      banner prompt-timeout #${device.banner.promptTimeout}#
      banner slip-ppp #${device.banner.slipPPP}#
    ''
    + self.lib.mkTitle device "VLANs"
    + (lib.concatMapAttrsStringSep "" (name: vlan: ''
        vlan ${toString vlan.id}
        name ${name}
      '')
      device.vlans)
    + lib.optionalString (device.vlans != {}) "exit\n"
    + self.lib.mkTitle device "ACLs"
    + self.lib.renderACLs device
    + self.lib.mkTitle device "IPv4 Settings"
    + self.lib.renderIpv4 device
    + self.lib.mkTitle device "Global IPv6 Settings"
    + self.lib.renderIpv6 device
    + self.lib.mkTitle device "Interfaces"
    + self.lib.mkSubTitle device "RESET"
    + builtins.concatStringsSep "" (map (int: ''
        default interface ${int}
      '')
      device.deviceSpec.interfaces)
    + lib.concatStringsSep "\n" (map (
        value:
          self.lib.renderInterface device value.name value.value
      ) (builtins.sort (a: b: a.value.priority < b.value.priority) (map (name: {
        inherit name;
        value = device.interfaces.${name};
      }) (builtins.attrNames device.interfaces))))
    + self.lib.mkTitle device "Routing"
    + self.lib.mkSubTitle device "Static Routes"
    + builtins.concatStringsSep "\n" (map (
        route:
          self.lib.renderRoute route
      )
      device.routes)
    + lib.optionalString ((builtins.stringLength device.extraPostConfig) != 0) ''
      ${self.lib.mkSubTitle device "Post Config"}
      ${device.extraPostConfig}
    ''
    + self.lib.mkSubTitle device "Render EEM"
    + self.lib.renderEEM device.eem
    + ''
      end
    '';
}

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
      banner motd ^C${device.banner.motd}^C
      banner login ^C${device.banner.login}^C
      banner config-save ^C${device.banner.configSave}^C
      banner exec ^C${device.banner.exec}^C
      banner incoming ^C${device.banner.incoming}^C
      banner prompt-timeout ^C${device.banner.promptTimeout}^C
      banner slip-ppp ^C${device.banner.slipPPP}^C
    ''
    + self.lib.renderUsers device
    + lib.optionalString (device.deviceSpec.deviceType == "switch")
    (
      self.lib.mkTitle device "VLANs"
      +
      (lib.concatMapAttrsStringSep "" (name: vlan: ''
        vlan ${toString vlan.id}
        name ${name}
      '')
        device.vlans)
      + lib.optionalString (device.vlans != {}) "exit\n"
    )
    + self.lib.renderKeys device
    + self.lib.mkTitle device "ACLs"
    + self.lib.renderACLs device
    + self.lib.mkTitle device "IPv4 Settings"
    + self.lib.renderIpv4 device
    + self.lib.mkTitle device "Global IPv6 Settings"
    + self.lib.renderIpv6 device
    + self.lib.mkTitle device "Interfaces"
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

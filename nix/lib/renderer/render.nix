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
    + "version ${device.version}\n"
    + device.extraPreConfig
    + ''
      vtp mode transparent
    ''
    + lib.optionalString (device.hostname != null) "hostname ${device.hostname}\n"
    + self.lib.mkTitle device "Banners"
    + lib.optionalString (device.banner.motd != "") "banner motd ${device.banner.seperator}${device.banner.motd}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.login != "") "banner login ${device.banner.seperator}${device.banner.login}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.configSave != "") "banner config-save ${device.banner.seperator}${device.banner.configSave}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.exec != "") "banner exec ${device.banner.seperator}${device.banner.exec}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.incoming != "") "banner incoming ${device.banner.seperator}${device.banner.incoming}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.promptTimeout != "") "banner prompt-timeout ${device.banner.seperator}${device.banner.promptTimeout}${device.banner.seperator}\n"
    + lib.optionalString (device.banner.slipPPP != "") "banner slip-ppp ${device.banner.seperator}${device.banner.slipPPP}${device.banner.seperator}\n"
    + self.lib.renderUsers device
    # + lib.optionalString (device.deviceSpec.deviceType == "switch")
    # (
    #   self.lib.mkTitle device "VLANs"
    #   +
    #   (lib.concatMapAttrsStringSep "" (name: vlan: ''
    #     vlan ${toString vlan.id}
    #     name ${name}
    #   '')
    #     device.vlans)
    #   + lib.optionalString (device.vlans != {}) "exit\n"
    # )
    + self.lib.renderKeys device
    + self.lib.mkTitle device "ACLs"
    + self.lib.renderACLs device
    + self.lib.mkTitle device "IPv4 Settings"
    + self.lib.renderIpv4 device
    + self.lib.mkTitle device "Global IPv6 Settings"
    + self.lib.renderIpv6 device
    + self.lib.mkTitle device "Interfaces"
    + self.lib.renderInterfaces device
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

{lib}: let
  funcs = lib.fix (self: {
    renderInterface = import ./renderInterface.nix {
      inherit lib;
      inherit self;
    };
    renderSwitchport = import ./renderSwitchport.nix {
      inherit lib;
      inherit self;
    };
    mkSubTitle = device: title: lib.optionalString device.comments "!==== ${title} ====!\n";
    mkTitle = device: title:
      lib.optionalString device.comments ''
        ! +----------------------------+
        ! ${title}
        ! +----------------------------+
      '';
    renderACLs = import ./renderACLs.nix {
      inherit lib;
      inherit self;
    };
    renderGlobalIPv6Settings = import ./renderGlobalIPv6Settings.nix {
      inherit lib;
      inherit self;
    };
    renderGlobalIPSettings = import ./renderGlobalIPSettings.nix {
      inherit lib;
      inherit self;
    };
    renderRoute = import ./renderRoute.nix {
      inherit lib;
      inherit self;
    };
    renderEEM = import ./renderEEM.nix {
      inherit lib;
      inherit self;
    };

    render = device:
      self.mkSubTitle device "Pre config"
      + device.extraPreConfig
      + ''
        vtp mode transparent
      ''
      + lib.optionalString (device.hostname != null) "hostname ${device.hostname}\n"
      + self.mkTitle device "Banners"
      + ''
        banner motd #${device.banner.motd}#
        banner login #${device.banner.login}#
        banner config-save #${device.banner.configSave}#
        banner exec #${device.banner.exec}#
        banner incoming #${device.banner.incoming}#
        banner prompt-timeout #${device.banner.promptTimeout}#
        banner slip-ppp #${device.banner.slipPPP}#
      ''
      + self.mkTitle device "VLANs"
      + (builtins.concatStringsSep "" (builtins.map (vlan: ''
          vlan ${toString vlan.id}
          name ${vlan.name}
        '')
        device.vlans))
      + lib.optionalString ((builtins.length device.vlans) != 0) "exit\n"
      + self.mkTitle device "ACLs"
      + self.renderACLs device
      + self.mkTitle device "Global IPv4 Settings"
      + self.renderGlobalIPSettings device
      + self.mkTitle device "Global IPv6 Settings"
      + self.renderGlobalIPv6Settings device
      + self.mkTitle device "Interfaces"
      + self.mkSubTitle device "RESET"
      + builtins.concatStringsSep "" (builtins.map (int: ''
          default interface ${int}
        '')
        device.deviceSpec.interfaces)
      + lib.concatStringsSep "\n" (map (
          value:
            self.renderInterface device value.name value.value
        ) (builtins.sort (a: b: a.value.priority < b.value.priority) (map (name: {
          inherit name;
          value = device.interfaces.${name};
        }) (builtins.attrNames device.interfaces))))
      + self.mkTitle device "Routing"
      + self.mkSubTitle device "Static Routes"
      + builtins.concatStringsSep "\n" (builtins.map (
          route:
            self.renderRoute route
        )
        device.routes)
      + lib.optionalString ((builtins.stringLength device.extraPostConfig) != 0) ''
        ${self.mkSubTitle device "Post Config"}
        ${device.extraPostConfig}
      ''
      + self.mkSubTitle device "Render EEM"
      + self.renderEEM device.eem
      + ''
        end
      '';
  });
in
  funcs

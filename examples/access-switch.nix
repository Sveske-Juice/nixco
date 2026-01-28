{lib, ...}: let
  vlans = {
    "LAN10" = 10;
    "LAN20" = 10;
    "Native" = 99;
    "Voice" = 150;
    "Management" = 200;
    "Printer" = 250;
    "Blackhole" = 999;
  };
in {
  config = {
    devices."mydevice" = {
      device = "C9200L-24P-4G";
      hostname = "ASW";
      banner.motd = ''
        Multiline
        Banner
      '';

      acl.standard = [
        {
          id = 1;
          rules = [
            {
              action = "permit";
              source = "any";
              log = true;
            }
          ];
        }
      ];

      vlans =
        lib.attrsets.mapAttrsToList (key: value: {
          name = key;
          id = value;
        })
        vlans;

      interfaces = {
        "g1/0/1-24,g1/1/1-4" = {
          shutdown = true;
          description = "Admin Shutdown";
          accessGroup = {
            id = 1;
            interface = "in";
          };
          switchport = {
            mode = "access";
            negotiate = false;
            vlan = vlans.Blackhole;
          };
        };

        "vlan ${toString vlans.Management}" = {
          description = "Management VLAN";
          ip.address = {
            address = "192.168.1.1";
            subnetmask = "255.255.255.0";
          };
        };

        "g1/0/1-4" = {
          description = "Access ports";
          switchport = {
            mode = "access";
            negotiate = false;
            portSecurity = {
              aging.time = 720;
              aging.type = "absolute";
              maximum = 4;
              violation = "restrict";
            };
          };
        };
      };
    };
  };
}

_: {
  config.devices."basic-switch" = {
    hostname = "S1";
    device = "C9200L-24P-4G";
    iosVersion = "69.420.67";

    vlans = [
      {
        id = 999;
        name = "Blackhole";
      }
      {
        id = 150;
        name = "Voice";
      }
    ];

    routes = [
      {
        destination = {
          address = "10.10.1.0";
          subnetmask = "255.255.255.0";
        };
        nextHop = "192.168.1.2";
      }
      {
        destination = {
          address = "10.10.2.0";
          subnetmask = "255.255.255.0";
        };
        nextHop = "192.168.2.2";
        exitInterface = "g1/0/1";
        distance = 5;
      }
      {
        ipv6 = true;
        destination = "2001:db8:a::1/64";
        nextHop = "2001:db8:1::1";
      }
    ];

    interfaces = {
      "vlan10" = {
        shutdown = false;
        description = "VLAN 10";
        ip.address.address = "10.10.10.100";
        ip.address.subnetmask = "255.255.255.0";
      };
      "vlan20" = {
        shutdown = false;
        ip.address = "dhcp";
        ipv6.linkLocal = "fe80::1/64";
        ipv6.addresses = ["2026:20::1/64"];
      };
      "g0/1-3" = {
        shutdown = false;
        switchport = {
          mode = "access";
          negotiate = false;
          portSecurity = {
            aging.time = 30; # 30min
            maximum = 3;
            violation = "restrict";
            stickyMac = true;
            secureMacAddresses = [
              "aaaa.bbbb.cccc"
              "dddd.eeee.ffff"
            ];
          };
        };
        ip.ipHelper = "10.10.10.1";
        ipv6.dhcp.relay = {
          destination = "2001:db8:acad::1::2";
          interface = "g1/1/1";
        };
      };
      "g0/4-6" = {
        channelGroup = {
          groupNumber = 1;
          mode = "on";
        };
      };
      "g1/0/1-2,g1/0/23" = {
        shutdown = false;
        switchport = {
          mode = "access";
          negotiate = false;
          portSecurity = {
            aging = {
              time = 720;
              static = true;
              type = "absolute";
            };
          };
        };
      };
      "GigabitEthernet0/0" = {
        shutdown = false;
        description = "Link to LAN1";
        switchport = {
          mode = "access";
          negotiate = false;
          trunk = {
            nativeVLAN = 1;
            allowed = "5-1005";
          };
        };
      };
      "port-channel 1" = {
        switchport.mode = "trunk";
        switchport.trunk.allowed = "1,2,20";
      };
    };
  };
}

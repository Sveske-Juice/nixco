_: {
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

  interfaces = {
    "vlan10" = {
      shutdown = false;
      description = "VLAN 10";
      ipAddress = {
        address = "10.10.10.100";
        subnetmask = "255.255.255.0";
      };
    };
    "vlan20" = {
      shutdown = false;
      ipAddress = "dhcp";
      ipv6LinkLocal = "fe80::1/64";
      ipv6Addresses = [ "2026:20::1/64" ];
    };
    "g0/1-3" = {
      shutdown = false;
      switchport = {
        mode = "access";
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
        portSecurity = {
          aging = {
            time = 720;
            static = true;
            type = "absoulute";
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
}

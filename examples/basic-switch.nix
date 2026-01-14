_: {
  device = "C9200L-24P-4G";
  iosVersion = "69.420.67";

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
    };
    "g0/1-3" = {
      shutdown = false;
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
  };
  name = "basic ahh switch";
}

_: {
  device = "C9200L-24P-4G";
  iosVersion = "69.420.67";
  interfaces = {
    "GigabitEthernet1/0/1" = {
      shutdown = false;
      switchport = {
        mode = "access";
        negotiate = false;
        vlan = 99;
      };
    };
  };
  name = "basic ahh switch";
}

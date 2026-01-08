config: {
    description = "";
    shutdown = true;
    switchport = {
        mode = if config.deviceSpec.deviceType == "switch"
          then "dynamic auto"
          else null;
      negotiate = true;
      vlan = 1;
      trunk = {
        nativeVLAN = 1;
        allowed = "1-1005";
      };
    };
  }

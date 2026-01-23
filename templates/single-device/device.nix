_: {
  config = {
    deviceSpec = {
      name = "My custom device";
      deviceType = "switch";
      interfaces = [
        "g1/1/0"
        "g1/1/1"
        "g1/1/2"
        "g1/1/3"
        "g1/1/4"
      ];
    };

    hostname = "SW";
    banner.motd = "Hello, World";
  };
}

{self, ...}: device:
self.mkSubTitle device "RESET"
+ ''
''
+ self.mkSubTitle device "Settings"
+ (
  if device.ipv6.routing
  then "ipv6 unicast-routing\n"
  else "no ipv6 unicast-routing\n"
)

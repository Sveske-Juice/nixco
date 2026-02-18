{ lib, self}: device:
self.mkSubTitle device "RESET"
+ ''
        no ip domain name
        no ip default-gateway
        no ip name-server
        no ip domain lookup
''
+ self.mkSubTitle device "Settings"
+ lib.optionalString (device.ip.domainName != null) "ip domain name ${device.ip.domainName}\n"
+ lib.optionalString (device.ip.defaultGateway != null) "ip default-gateway ${device.ip.defaultGateway}\n"
+ lib.optionalString device.ip.domainLookup.enable "ip domain lookup\n"
+ (
  if device.ip.routing
    then "ip routing\n"
  else "no ip routing\n"
)
+ (
  if device.ip.http.server.enable
    then "ip http server\n"
  else "no ip http server\n"
)
+ (
  if device.ip.http.secureServer.enable
    then "ip http secure-server\n"
  else "no ip http secure-server\n"
)

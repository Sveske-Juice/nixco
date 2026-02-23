{ lib, self}: route:
(
  if route.ipv6
    then "ipv6 "
  else "ip "
)
+ "route "
+ (
  if route.ipv6
    then route.destination
  else "${route.destination.address} ${route.destination.subnetmask}"
)
+ " "
+ (lib.optionalString (route.exitInterface != null) "${route.exitInterface} ")
+ (lib.optionalString (route.nextHop != null) "${route.nextHop} ")
+ (toString route.distance)

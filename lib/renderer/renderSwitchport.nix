{ lib, self}: value:
''
        switchport
        switchport mode ${value.switchport.mode}
''
+ lib.optionalString (!value.switchport.negotiate) "switchport nonegotiate\n"
+ lib.optionalString (value.switchport.mode == "access")
"switchport access vlan ${toString value.switchport.vlan}\n"
+ lib.optionalString (value.switchport.mode == "trunk")
''
        switchport trunk native vlan ${toString value.switchport.trunk.nativeVLAN}
        switchport trunk allowed vlan ${value.switchport.trunk.allowed}
''
+ lib.optionalString (value.switchport.portSecurity != null) (
  ''
          switchport port-security
          switchport port-security maximum ${toString value.switchport.portSecurity.maximum}
          switchport port-security violation ${value.switchport.portSecurity.violation}
  ''
  + lib.optionalString ((builtins.length value.switchport.portSecurity.secureMacAddresses) != 0) (
    builtins.concatStringsSep "" (map (addr: "switchport port-security mac-address ${addr}\n") value.switchport.portSecurity.secureMacAddresses)
  )
  + lib.optionalString value.switchport.portSecurity.stickyMac
  "switchport port-security mac-address sticky\n"
  + lib.optionalString (value.switchport.portSecurity.aging != null)
  (
    ''
            switchport port-security aging time ${toString value.switchport.portSecurity.aging.time}
            switchport port-security aging type ${value.switchport.portSecurity.aging.type}
    ''
    + (lib.optionalString value.switchport.portSecurity.aging.static
      "switchport port-security aging static")
  )
)

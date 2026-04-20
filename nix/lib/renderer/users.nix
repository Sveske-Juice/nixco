{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.renderUsers = device:
    self.lib.mkTitle device "Users"
    + lib.optionalString (device.enable != null) 
    "enable algorithm-type ${device.enable.algorithmType} secret ${device.enable.secret}\n"
    + (
      lib.concatMapAttrsStringSep "\n" (name: user: self.lib.renderUser name user) device.username
    );
  flake.lib.renderUser = name: user:
    "username ${name} "
    +
    "privilege ${toString user.privilege} "
    +
    "algorithm-type ${user.algorithmType} "
    + (
      if user.nopassword then "nopassword"
      else "secret ${user.secret}"
    )
    +
    "\n"
  ;
}

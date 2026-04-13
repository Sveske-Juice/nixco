{
  inputs,
  lib,
  self,
  ...
}: {
  config.flake.lib.eval = userModules:
    lib.evalModules {
      modules = (builtins.attrValues self.nixcoModules) ++ userModules;
      specialArgs = {inherit inputs lib;};
    };
}

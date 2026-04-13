{ self, ... }: 
let
  nixcoModule = import ../../flake-module.nix { inherit self; };
in {
  flake.flakeModules.nixco = nixcoModule;
  flake.flakeModules.default = self.flakeModules.nixco;

  imports = [ nixcoModule ];
}

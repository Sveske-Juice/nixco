{ self, inputs, ... }: 
let
  nixcoModule = import ../../flake-module.nix { inherit self inputs; };
in {
  flake.flakeModules.nixco = nixcoModule;
  flake.flakeModules.default = self.flakeModules.nixco;

  imports = [ nixcoModule ];
}

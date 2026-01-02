{
  description = "Declarative configuration engine for Cisco IOS devices";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, ...}: 
    flake-parts.lib.mkFlake { inherit inputs; } ( top @ {...}: let
      nixco-lib = import ./lib { inherit (inputs.nixpkgs) lib; };
    in {
      imports = [
      ];
      flake = {
      };

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, pkgs, ...}: let
        deviceCfg = nixco-lib.evalDevice ./examples/basic-switch.nix;
        rendered = nixco-lib.renderConfig { inherit (inputs.nixpkgs) lib; } deviceCfg.config;
      in {
        packages.test = pkgs.writeText "test.cfg" rendered;
      };
  });
}

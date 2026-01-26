{
  description = "Basic nixco project for a single device";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixco.url = "github:Sveske-Juice/nixco";
    nixco.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixco,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (_: let
      devices = (nixco.nixcoLib.eval [ ./default.nix ]).config.devices;
    in {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = {pkgs, ...}: {
        packages.default = nixco.nixcoLib.renderAllDevices pkgs devices;
      };
    });
}

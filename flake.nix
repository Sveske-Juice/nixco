{
  description = "Declarative configuration engine for Cisco IOS devices";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} (_: let
      nixcoLib = import ./lib {inherit (inputs.nixpkgs) lib;};
    in {
      imports = [
        ./treefmt.nix
      ];
      flake = {
      };

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        deviceCfg = nixcoLib.evalDevice ./examples/access-switch.nix;
        rendered = nixcoLib.renderConfig.render {inherit (inputs.nixpkgs) lib;} deviceCfg.config;
      in {
        packages.test = pkgs.writeText "test.cfg" rendered;
        packages.default = pkgs.callPackage ./package.nix {};

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            clang-tools
            clang
            pkg-config
            ninja
            meson
            llvmPackages_latest.libstdcxxClang
            llvmPackages_latest.libcxx
            valgrind
            just
            gdb

            libssh
            fmt
            spdlog
          ];
        };
      };
    });
}

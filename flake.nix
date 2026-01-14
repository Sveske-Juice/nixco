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
      nixco-lib = import ./lib {inherit (inputs.nixpkgs) lib;};
    in {
      imports = [
        ./treefmt.nix
      ];
      flake = {
      };

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        deviceCfg = nixco-lib.evalDevice ./examples/basic-switch.nix;
        rendered = nixco-lib.renderConfig.render {inherit (inputs.nixpkgs) lib;} deviceCfg.config;
      in {
        packages.test = pkgs.writeText "test.cfg" rendered;
        packages.default = pkgs.callPackage ./package.nix {};

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            clang-tools
            clang
            pkg-config
            ninja
            bear
            meson
            llvmPackages_latest.libstdcxxClang
            llvmPackages_latest.libcxx
            valgrind
            libssh
            just
            gdb
            fmt
          ];

          shellHook = ''
            export PKG_CONFIG_PATH=${pkgs.libssh}/lib/pkgconfig:$PKG_CONFIG_PATH
          '';
        };
      };
    });
}

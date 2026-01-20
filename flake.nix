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
        # Expose nixcoLib from flake
        inherit nixcoLib;

        templates = {
          default = {
            path = ./templates/single-device;
            description = "Nixco single device template";
            welcomeText = ''
              This template contains a flake.nix which contains
              a default package output, which when built, renders
              your device's config (device.nix):
              $ nix build .#
            '';
          };
        };
      };

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        examples = inputs.nixpkgs.lib.fileset.toList (inputs.nixpkgs.lib.fileset.fileFilter (file: file.hasExt "nix") ./examples);
        renderExamples = builtins.listToAttrs (map (file: let
            exampleName = inputs.nixpkgs.lib.strings.replaceString ".nix" "" (builtins.baseNameOf file);
            deviceCfg = nixcoLib.evalDevice file;
            rendered = nixcoLib.renderConfig.render {inherit (inputs.nixpkgs) lib;} deviceCfg.config;
          in {
            name = exampleName;
            value = pkgs.writeText exampleName rendered;
          })
          examples);
      in {
        packages.default = pkgs.callPackage ./package.nix {};
        checks = renderExamples;

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

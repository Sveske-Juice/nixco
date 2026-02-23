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
            path = ./templates/default;
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
        allDevices = nixcoLib.eval examples;
        renderAll = builtins.mapAttrs (_deviceName: value:
          pkgs.writeText "test" (nixcoLib.renderConfig.render {inherit (inputs.nixpkgs) lib;} value))
        allDevices.config.devices;

        minimalShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            libssh
            fmt
            spdlog
          ];
          nativeBuildInputs = with pkgs; [
            clang-tools
            pkg-config
            ninja
            meson
            just
          ];
        };
      in {
        packages.default = pkgs.callPackage ./package.nix {};
        checks = renderAll;

        devShells.default = minimalShell;
        devShells.full = minimalShell.overrideAttrs (old: {
          nativeBuildInputs = with pkgs; old.nativeBuildInputs ++ [
            valgrind
            gdb
          ];
        });
      };
    });
}

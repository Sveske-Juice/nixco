{pkgs ? import <nixpkgs> {}}: pkgs.stdenv.mkDerivation rec {
  pname = "nixco";
  version = builtins.readFile ./VERSION;

  src = ./.;

  nativeBuildInputs = [
    pkgs.clang
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.libssh
    pkgs.fmt
    pkgs.spdlog
  ];
}

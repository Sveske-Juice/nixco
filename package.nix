{pkgs ? import <nixpkgs> {}}: pkgs.stdenv.mkDerivation rec {
  pname = "nixco";
  version = "1.0.0";

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
  ];
}

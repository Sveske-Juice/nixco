{pkgs ? import <nixpkgs> {}}: pkgs.stdenv.mkDerivation rec {
  pname = "nixco";
  version = "1.0.0";

  src = pkgs.lib.sourceByRegex ./. [
    "^src.*"
    "CMakeLists.txt"
  ];

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.libssh
  ];
}

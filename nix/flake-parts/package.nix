{
  perSystem = {pkgs, ...}: {
    packages.default = pkgs.stdenv.mkDerivation {
      pname = "nixco";
      version = builtins.readFile ../../VERSION;

      src = ../..;

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
    };
  };
}

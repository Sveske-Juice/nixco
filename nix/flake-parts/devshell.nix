{
  perSystem = {pkgs, ...}: let
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
    devShells.default = minimalShell;
    devShells.full = minimalShell.overrideAttrs (old: {
      nativeBuildInputs = with pkgs;
        old.nativeBuildInputs
        ++ [
          valgrind
          gdb
        ];
    });
  };
}

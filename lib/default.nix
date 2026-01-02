{lib}: {
  evalDevice = device:
    lib.evalModules {
      modules = [../modules device];
      specialArgs = {inherit lib;};
    };
  renderConfig = import ./render.nix;
}

{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        deadnix = {
          enable = true;
          priority = 10;
        };

        statix = {
          enable = true;
          priority = 20;
        };

        alejandra = {
          enable = true;
          priority = 30;
        };
      };
    };
  };
}

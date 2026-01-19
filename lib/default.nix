{lib}: let
  # Exposed nixcoLib types, functions etc.
  nixcoLib = {
    # nixcoLib global types
    types = {
      ipAddrMaskType = lib.types.submodule (_: {
        options = {
          address = lib.mkOption {
            type = lib.types.str;
            example = "192.168.1.1";
          };
          subnetmask = lib.mkOption {
            type = lib.types.str;
            example = "255.255.255.0";
          };
        };
      });
    };

    # nixcoLib global functions
  };
in {
  evalDevice = device: let
    result = lib.evalModules {
      modules = [../modules device];
      specialArgs = {
        inherit lib;
        inherit nixcoLib;
      };
    };

    failedAssertions = builtins.filter (a: !a.assertion) result.config.assertions;
  in
    if failedAssertions == []
    then result
    else
      throw (
        "Device module assertion failed:\n"
        + builtins.concatStringsSep "\n" (map (a: "- " + a.message) failedAssertions)
      );
  renderConfig = import ./render.nix;
}

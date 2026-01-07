{lib}: {
  evalDevice = device: let
    result = lib.evalModules {
      modules = [../modules device];
      specialArgs = {inherit lib;};
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

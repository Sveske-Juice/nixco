{lib}: let
  # Exposed nixcoLib types, functions etc.
  nixcoLib = {
    types = import ./types.nix lib;

    # nixcoLib global functions
  };
in {
  eval = files: let
    result = lib.evalModules {
      modules = [../modules] ++ files;
      specialArgs = {
        inherit lib;
        inherit nixcoLib;
      };
    };

    # Collect all device-level assertions
    allDeviceAssertions = builtins.concatLists (
      map (
        deviceName: let
          deviceConfig = result.config.devices.${deviceName};
        in
          deviceConfig.assertions
      ) (builtins.attrNames result.config.devices)
    );
    failedAssertions = builtins.filter (a: !a.assertion) allDeviceAssertions;
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

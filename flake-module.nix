{ self, inputs }:
{ config, lib, ... }: {
  options.nixco = lib.mkOption {
    type = lib.types.submodule {
      imports = [ self.nixcoModules.device ];
    };
    default = {};
  };

  config = {
    flake.nixcoConfigurations = let
      # Access the library via self
      evaluatedDevices = self.lib.eval [ config.nixco ];
    in
      self.lib.renderAll evaluatedDevices.config.devices;

    perSystem = { pkgs, ... }: {
      packages = lib.mapAttrs (name: text:
        pkgs.writeText "${name}.ios" text
      ) config.flake.nixcoConfigurations;
    };
  };
}

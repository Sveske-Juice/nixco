{
  self,
  inputs,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.flakeModules.default = self.flakeModules.nixco;
  flake.flakeModules.nixco = {config, ...}: {
    options.nixco = lib.mkOption {
      description = ''
        Project-level nixco configuration.
      '';
      # this options submodule should be split up into multiple files
      type = lib.types.submodule {
        imports = [
          self.nixcoModules.device
        ];
      };
      default = {};
    };
    config.flake.nixcoConfigurations = let
      evaluatedDevices = self.lib.eval [config.nixco];
    in
      self.lib.renderAll evaluatedDevices.config.devices;

    config.perSystem = {pkgs, ...}: {
      packages =
        lib.mapAttrs (
          name: renderedConfig:
            pkgs.writeText "${name}.ios" renderedConfig
        )
        config.flake.nixcoConfigurations;
    };
  };
}

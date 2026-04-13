{inputs, ...}: {
  config.systems = inputs.nixpkgs.lib.systems.flakeExposed;
}

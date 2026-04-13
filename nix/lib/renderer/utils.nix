{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib = {
    mkSubTitle = device: title: lib.optionalString device.comments "!==== ${title} ====!\n";
    mkTitle = device: title:
      lib.optionalString device.comments ''
        ! +----------------------------+
        ! ${title}
        ! +----------------------------+
      '';
  };
}

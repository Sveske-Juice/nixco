{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib = {
    indentLines = text:
      let
        lines = lib.splitString "\n" text;
        # Don't indent empty lines (avoids trailing spaces on blank lines)
        indented = map (line: if line == "" then "" else " ${line}") lines;
      in
        lib.concatStringsSep "\n" indented;
    mkSubTitle = device: title: lib.optionalString device.comments "!==== ${title} ====!\n";
    mkTitle = device: title:
      lib.optionalString device.comments ''
        ! +----------------------------+
        ! ${title}
        ! +----------------------------+
      '';
  };
}

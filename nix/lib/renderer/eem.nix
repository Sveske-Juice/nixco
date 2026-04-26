{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.lib.renderEEMApplet = label: applet: let
    body =
      lib.optionalString (applet.description != null) "description ${applet.description}\n"
      +
      # Render event
      ''
        event ${applet.event.eventStr}
      ''
      +
      # Render actions
      (builtins.concatStringsSep "\n" (map (
          action: ''action ${action.label} ${action.actionStr}''
        )
        applet.actions))
      + "\n";
  in
    "event manger applet ${label}"
    + "\n"
    + self.lib.indentLines body;

  flake.lib.renderEEM = eem:
  # Render all applets
    builtins.concatStringsSep "\n"
    (
      lib.attrsets.mapAttrsToList
      (label: applet: self.lib.renderEEMApplet label applet)
      eem.applets
    );
}

{lib, ...}: eem: let
  renderEEMApplet = label: applet:
    ''
      event manager applet ${label}
    ''
    + lib.optionalString (applet.description != null) "description ${applet.description}\n"
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
  # Render all applets
  builtins.concatStringsSep "\n"
  (
    lib.attrsets.mapAttrsToList
    (label: applet: renderEEMApplet label applet)
    eem.applets
  )

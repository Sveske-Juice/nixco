{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.banner = {
    options.banner = lib.mkOption {
      default = {};
      type = lib.types.submodule {
        options = {
          seperator = lib.mkOption {
            description = "The seperator symbol to use";
            type = lib.types.str;
            default = "^";
          };
          motd = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Message of the Day banner";
          };
          configSave = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Message for saving configuration";
          };
          login = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Login banner";
          };
          exec = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "EXEC process creation baner";
          };
          incoming = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Incoming terminal line banner";
          };
          promptTimeout = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Message when a prompt times out";
          };
          slipPPP = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Message for SLIP/PPP connections";
          };
        };
      };
    };
  };
}

{lib, ...}: {
  options = {
    banner = lib.mkOption {
      default = {};
      type = lib.types.submodule (_: {
        options = {
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
      });
    };
  };
}

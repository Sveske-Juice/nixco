# Embedded Event Manager
{inputs, self, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  flake.nixcoModules.eem = {config, ...}: {
    options = {
      eem = lib.mkOption {
        description = "Embedded Event Manager configuration";
        default = {};
        type = lib.types.submodule {
          options = {
            apples = lib.mkOption {
              default = {};
              description = "EEM applets";
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  description = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                  };
                  actions = lib.mkOption {
                    default = [];
                    type = lib.types.listOf (lib.types.submodule {
                      label = lib.mkOption {
                        type = lib.types.str;
                      };
                      # TODO: make options foreach action:
                      # append               Append to a variable
                      # break                Break out of a conditional loop
                      # cli                  Execute a CLI command
                      # cns-event            Send a CNS event
                      # comment              add comment
                      # context              Save or retrieve context information
                      # continue             Continue to next loop iteration
                      # counter              Modify a counter value
                      # decrement            Decrement a variable
                      # divide               Divide
                      # else                 else conditional
                      # elseif               elseif conditional
                      # end                  end conditional block
                      # exit                 Exit from applet run
                      # export-to-telemetry  Export EEM variables to Telemetry
                      # file                 file operations
                      # force-switchover     Force a software switchover
                      # foreach              foreach loop
                      # gets                 get line of input from active tty
                      # handle-error         On error action
                      # help                 Read/Set parser help buffer
                      # if                   if conditional
                      # increment            Increment a variable
                      # info                 Obtain system specific information
                      # mail                 Send an e-mail
                      # multiply             Multiply
                      # policy               Run a pre-registered policy
                      # publish-event        Publish an application specific event
                      # puts                 print data to active tty
                      # regexp               regular expression match
                      # reload               Reload system
                      # set                  Set a variable
                      # snmp-object-value    Specify value for the SNMP get request
                      # snmp-trap            Send an SNMP trap
                      # string               string commands
                      # subtract             Subtract
                      # syslog               Log a syslog message
                      # track                Read/Set a tracking object
                      # wait                 Wait for a specified amount of time
                      # while                while loop
                      actionStr = lib.mkOption {
                        type = lib.types.str;
                      };
                    });
                  };
                  event = lib.mkOption {
                    default = [];
                    type = lib.types.submodule {
                      options = {
                        # TODO: make options for:
                        # application         Application specific event
                        # cli                 CLI event
                        # config              Configuration policy event
                        # counter             Counter event
                        # env                 Environmental event
                        # gold                GOLD event
                        # identity            Identity event
                        # interface           Interface event
                        # ioswdsysmon         IOS WDSysMon event
                        # ipsla               IPSLA Event
                        # mat                 MAC address table event
                        # neighbor-discovery  Neighbor Discovery event
                        # nf                  NF Event
                        # none                Manually run policy event
                        # oir                 OIR event
                        # rf                  Redundancy Facility event
                        # routing             Routing event
                        # snmp                SNMP event
                        # snmp-notification   SNMP Notification Event
                        # snmp-object         SNMP object event
                        # syslog              Syslog event
                        # tag                 event tag identifier
                        # timer               Timer event
                        eventStr = lib.mkOption {
                          type = lib.types.str;
                        };
                      };
                    };
                  };
                };
              });
            };
          };
        };
      };
    };

    config.eem.applets = lib.mkMerge [
      (let
        pcInterfaces = lib.attrsets.filterAttrs (_: value: value.portChannel) config.interfaces;
        renderedPCInts = builtins.concatStringsSep "\n" (lib.mapAttrsToList (
          intname: intvalue:
          self.lib.renderer.renderInterface config intname intvalue
        )
          pcInterfaces);
        lines = builtins.filter (l: l != "") (lib.splitString "\n" renderedPCInts);
        # FIX_PORTCHANNELS EEM Intial boot applet
      in {
        "FIX_PORTCHANNELS" = {
          event.eventStr = ''syslog pattern "SYS-5-RESTART" occurs 1 maxrun 120'';
          actions =
            [
              {
                label = "0.1";
                actionStr = "wait 30";
              }
              {
                label = "0.2";
                actionStr = ''cli command "enable"'';
              }
              {
                label = "0.3";
                actionStr = ''cli command "configure terminal"'';
              }
              # Self destruct
              {
                label = "0.4";
                actionStr = ''cli command "no event manager applet FIX_PORTCHANNELS"'';
              }
            ]
            ++ lib.lists.imap0 (
              idx: line: {
                label = "20.${lib.fixedWidthString 3 "0" (toString idx)}";
                actionStr = ''cli command "${line}"'';
              }
            )
            lines;
        };
      })
      (let
        renderKeyCmd = key:
          "crypto key generate ${key.type} "
          + (
            if key.type == "rsa"
              then
              "modulus ${toString key.rsaOpts.modulus} "
              + lib.optionalString (key.rsaOpts.label != null) "label ${key.rsaOpts.label} "
            else # ec
              "keysize ${toString key.ecOpts.keysize} "
          );
      in 
        lib.listToAttrs (lib.lists.imap0 (
          idx: key: {
            name = "GEN_KEY_${toString idx}";
            value = {
              event.eventStr = ''syslog pattern "SYS-5-RESTART" occurs 1 maxrun 120'';
              actions = [
                {
                  label = "0.1";
                  actionStr = "wait 10";
                }
                {
                  label = "0.2";
                  actionStr = ''cli command "enable"'';
                }
                {
                  label = "0.3";
                  actionStr = ''cli command "configure terminal"'';
                }
                # Self destruct
                {
                  label = "0.4";
                  actionStr = ''cli command "no event manager applet GEN_KEY_${toString idx}"'';
                }
                {
                  label = "0.5";
                  actionStr = ''cli command "end"'';
                }
                {
                  label = "1";
                  actionStr = ''cli command "${renderKeyCmd key}"'';
                }
              ];
            };
          }
        )
          config.keys))
    ];
  };
  # TODO: assert applet label no spaces in str
}

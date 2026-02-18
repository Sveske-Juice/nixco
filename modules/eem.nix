{lib, config, ...}: let
  actionType = lib.types.submodule (_: {
    options = {
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
    };
  });
  eventType = lib.types.submodule (_: {
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
  });
  appletType = lib.types.submodule (appletName: {
    options = {
      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      actions = lib.mkOption {
        type = lib.types.listOf actionType;
        default = [];
      };
      event = lib.mkOption {
        type = eventType;
      };
    };
  });
in {
  options = {
    eem = lib.mkOption {
      type = lib.types.submodule (_: {
        options.applets = lib.mkOption {
          type = lib.types.attrsOf appletType;
          default = {};
        };
      });
    };
  };

  config.assertions = [
    # TODO: assert applet label no spaces in str
  ];
}

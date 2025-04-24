{ pkgs, misc, lib, config, options, inputs, ... }: 

with lib;

let
  # Requires 
  cfg = config.services.kitty-save-session;
in {
  options.services.kitty-save-session = {
    enable = mkEnableOption "Kitty session saving service. Requirees kitty remote control to be enabled, and single-process mode (or only the most recent window will be saved).";

    package = mkOption {
      type = types.package;
      default = pkgs.stdenv.mkDerivation {
          pname = "kitty-save-session";
          version = "da95124be1bfc209051e663d1faba80fcaa5dd13"; # match to the rev
          src = pkgs.fetchFromGitHub {
            owner = "mtalexan";
            repo = "kitty-save-session";
            rev = "da95124be1bfc209051e663d1faba80fcaa5dd13"; # current head of 'main' branch
            sha256 = "sha256-+whfY7h//y/VBNHTJcttbOTEcRA85ntSLPdFrZrR/z4=";
            #sha256 = lib.fakeSha256;
          };

          installPhase = ''
            mkdir -p $out/bin
            cp kitty-convert-dump.py $out/bin/
            chmod +x $out/bin/kitty-convert-dump.py
            cp kitty-save-session-common.incl $out/bin/
            # The kitty-save-session-common.incl needs to be in the same folder as the *.sh files, but doesn't need to be executable.
            cp kitty-save-session*.sh $out/bin/
            chmod +x $out/bin/kitty-save-session*.sh
          '';

          # The kitty-convert-dump.py script has no module dependencies, so we just need Python3.
          buildInputs = [ pkgs.python3 ];
      };
      description = "The kitty-save-session package";
    };

    interval = mkOption {
      type = types.str;
      default = "5m";
      description = "How often to save Kitty sessions (systemd timer format)";
    };

    listenSockPattern = mkOption {
      type = types.str;
      # make sure this matches with the kitty.conf 'listen_on' setting, and the allow_remote_control setting is enabled
      default = "@kitty-{kitty_pid}.sock";
      description = ''
        The pattern used for the kitty.conf 'listen_on' setting, without the 'unix:' prefix. Must contain the kitty
        placeholder {kitty_pid} in the name. If it's a path to a socket file, the placeholder must be in the file name
        and not in the path. Datagram sockets may be used with the '@' prefix on the name.
      '';
    };

    saveDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.cache/kitty/saved-sessions";
      description = ''
        Directory to save the Kitty session file. This folder will be created if it doesn't exist.
        It will be deleted and replaced whenever a new set of sesions is saved.
      '';
    };

    saveOpts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of options to the python parser that converts the current state JSON output into a session
        input file. See https://github.com/mtalexan/kitty-save-session/blob/main/kitty-convert-dump.py
        for available options.
      '';
    };

    notifyOnFailure = mkEnableOption "Send a desktop notification with noti if the save-session service encounters an error.";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # the one-host service to actually save the config to the output folder
    systemd.user.services.kitty-save-session = {
      Unit = {
        Description = "Save Kitty terminal sessions";
        After = "graphical-session.target";
        PartOf = "graphical-session.target";
      };

      Service = {
        Type = "oneshot";
        # use a shell script to capture output to the journal
        ExecStart = ''${cfg.package}/bin/kitty-save-session-all.sh'';
        # the one-shot systemd service to trigger when a failure occurs.
        OnFailure= mkIf cfg.notifyOnFailure "kitty-save-session-failure-notify.service";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "kitty-save-session";
        Environment = [
          "KITTY_SESSION_SOCK_PATTERN=${cfg.listenSockPattern}"
          "KITTY_SESSION_SAVE_DIR=${cfg.saveDir}"
          "KITTY_SESSION_SAVE_OPTS=${concatStringsSep " " cfg.saveOpts}"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.kitty-save-session-failure-notify = mkIf cfg.notifyOnFailure {
      Unit = {
        Description = "Notify on failure of kitty-save-session";
        PartOf = "kitty-save-session.service";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.noti}/bin/noti -t 'Kitty Session Save Failed' -m 'Systemd service unit kitty-save-session.service failed. See journalctl --user -xu kitty-save-session.service for details'";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "kitty-save-session-failure-notify";
      };
    };

    # The re-occurring timer that triggers the save
    systemd.user.timers.kitty-save-session = {
      Unit = {
        Description = "Timer for saving Kitty terminal sessions";
      };

      Timer = {
        OnActiveSec = "2m";
        OnUnitActiveSec = cfg.interval;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # Add proper shell integration by setting the environment variables to match
    home.sessionVariables = {
      KITTY_SESSION_SOCK_PATTERN="${cfg.listenSockPattern}";
      KITTY_SESSION_SAVE_DIR="${cfg.saveDir}";
    };
  };
}
# vim: ts=2:sw=2:expandtab
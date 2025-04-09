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
        name = "kitty-save-session";
        version = "bc656f2682758f1ba85dd106ddcb10b1e0a63b7c"; # match to the rev
        src = pkgs.fetchFromGitHub {
          owner = "mtalexan";
          repo = "kitty-save-session";
          rev = "bc656f2682758f1ba85dd106ddcb10b1e0a63b7c"; # current head of 'main' branch
          sha256 = "sha256-CUCtjrDgVDY0hOF6h+y3dVk/CzX9dpsJOzWivOHc07k=";
          #sha256 = lib.fakeSha256;
        };

        installPhase = ''
          mkdir -p $out/bin
          cp kitty-convert-dump.py $out/bin/
          chmod +x $out/bin/kitty-convert-dump.py
          cp kitty-save-session*.sh $out/bin/
          chmod +x $out/bin/kitty-save-session*.sh
        '';

        buildInputs = [ pkgs.python3 ];
      };
      description = "The kitty-save-session package";
    };

    interval = mkOption {
      type = types.str;
      default = "5m";
      description = "How often to save Kitty sessions (systemd timer format)";
    };

    listenSockDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.cache/kitty/sessions";
      description = "Directory to save the Kitty session file. This file can be reloaded with 'kitty --session <path>/kitty-session.kitty' to restore the session.";
    };

    saveDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.cache/kitty/saved-sessions";
      description = "Directory to save the Kitty session file. This file can be reloaded with 'kitty --session <path>/kitty-session.kitty' to restore the session.";
    };

    saveOpts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of options to the python parser that converts the current state JSON output into a session input file. See https://github.com/mtalexan/kitty-save-session/blob/main/kitty-convert-dump.py for available options.";
    };
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
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.saveDir}";
        # use a shell script to capture output to the journal
        ExecStart = ''${cfg.package}/bin/kitty-save-session-all.sh'';
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "kitty-save-session";
        Environment = [
          "KITTY_SESSION_SOCKS_PATH=${cfg.listenSockDir}"
          "KITTY_SESSION_SAVE_DIR=${cfg.saveDir}"
          "KITTY_SESSION_SAVE_OPTS=${concatStringsSep " " cfg.saveOpts}"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
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
      KITTY_SESSION_SOCKS_DIR="${cfg.listenSockDir}";
      KITTY_SESSION_SAVE_DIR="${cfg.saveDir}";
    };
  };
}
# vim: ts=2:sw=2:expandtab
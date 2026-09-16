# This installs a copilot-api systemd user service, and a Desktop file to perform auth and start it.
# Auth credentials are saved and the session should be maintained across reboots.
{ pkgs, misc, lib, config, options, ... }: {
  options.custom.copilot-api = with lib; {
    autostart = {
      enable = mkEnableOption "Automatically start the copilot-api systemd user service at login";
      # If autostart is enabled, broken networking or not being authenticated yet will cause the systemd service to fail.
      # We set start limit burst and start limit interval so the systemd service doesn't just keep retrying constantly.
      # If it fails, running the Desktop file will try to restart it fresh, as well as giving an opportunity to authenticate
      # if needed.

      start_limit_burst = mkOption {
        type = types.ints.positive;
        default = 5;
        description = "Maximum number of times the systemd service will restart within the start_limit_interval before giving up (and notifying the user). Includes the first start attempt.";
      };

      start_limit_interval = mkOption {
        type = types.str;
        default = "5m";
        description = "Duration over which the start_limit_burst is measured. Format is a systemd time value.";
      };
    };

    port = mkOption {
      type = types.port;
      # the built-in default port
      default = 4141;
      description = "TCP port on which copilot-api listens.";
    };

    wait = mkOption {
      type = types.bool;
      default = true;
      description = "When set, rate limited requests wait for cooldown rather than failing outright.";
    };

    account_type = mkOption {
      type = types.enum [ "individual" "business" "enterprise" ];
      default = "enterprise";
      description = "GitHub Copilot account type. Controls which models are visible.";
    };

    enterprise_url = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional GitHub Enterprise Server URL, if GitHub Organization authentication isn't sufficient.";
    };

    api_home = mkOption {
      type = types.nullOr types.str;
      # Default is set by the copilot-api app itself, don't try to force override here unless
      # explictly requested.
      default = null;
      description = ''
        Optional absolute API app-data directory. When set, both the daemon and copilot-api-auth helper use it so they share
        cached credentials. Default is $XDG_DATA_HOME/copilot-api (~/.local/share/copilot-api).
      '';
    };
  };

  config = let
    cfg = config.custom.copilot-api;

    api_home_args = lib.optional (cfg.api_home != null) "--api-home=${cfg.api_home}";
    enterprise_url_args = lib.optional (cfg.enterprise_url != null) "--enterprise-url=${cfg.enterprise_url}";
    start_args = [
      "start"
      "--port=${toString cfg.port}"
      "--account-type=${cfg.account_type}"
    ] ++ lib.optional cfg.wait "--wait" ++ enterprise_url_args ++ api_home_args;

    # Wrapper script for running interactive auth.
    auth_helper = pkgs.writeShellScriptBin "copilot-api-auth" ''
      exec ${lib.escapeShellArgs ([ "${pkgs.copilot-api}/bin/copilot-api" "auth" "--provider=copilot" ] ++ enterprise_url_args ++ api_home_args)}
    '';

    # Checks if auth is already valid, and if not starts the user interactive auth flow. If auth succeeds, it starts the copilot-api service.
    start_helper = pkgs.writeShellScriptBin "copilot-api-start" ''
      if ! ${lib.escapeShellArgs ([ "${pkgs.copilot-api}/bin/copilot-api" "doctor" ] ++ enterprise_url_args ++ api_home_args)}; then
        ${auth_helper}/bin/copilot-api-auth
        auth_status=$?
        if [[ $auth_status -ne 0 ]]; then
          ${pkgs.libnotify}/bin/notify-send --urgency=critical --app-name="Copilot API" "Copilot API authentication failed" "Review the terminal output, then try again."
          printf '\nAuthentication failed (exit status %s). Press Enter to close this window.\n' "$auth_status"
          read -r
          exit "$auth_status"
        fi
      fi

      exec ${pkgs.systemd}/bin/systemctl --user start copilot-api.service
    '';
  in {
    home.packages = [
      pkgs.copilot-api
      auth_helper
      start_helper
      # needed for one of the helper scripts to send a desktop notification
      pkgs.libnotify
    ];

    # Service unit always exists, we conditionally enable it by default by adding WantedBy
    systemd.user.services.copilot-api = {
      Unit = {
        Description = "Copilot API gateway";
        OnFailure = [ "copilot-api-failure-notify.service" ];
        StartLimitBurst = cfg.autostart.start_limit_burst;
        StartLimitIntervalSec = cfg.autostart.start_limit_interval;
      };

      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs ([ "${pkgs.copilot-api}/bin/copilot-api" ] ++ start_args);
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "copilot-api";
      };

      Install = lib.mkIf cfg.autostart.enable {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.services.copilot-api-failure-notify = {
      Unit = {
        Description = "Notify when the Copilot API gateway fails";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical --app-name='Copilot API' 'Copilot API server failed' 'See journalctl --user -u copilot-api.service for details.'";
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "copilot-api-failure-notify";
      };
    };

    # Desktop entry to check/perform auth and manually start the server.
    # The actual server runs as a systemd unit, so this will exit once the server is started.
    xdg.desktopEntries.copilot-api = {
      name = "Copilot API";
      comment = "Authenticate with GitHub and start the Copilot API gateway";
      exec = "${start_helper}/bin/copilot-api-start";
      terminal = true;
      type = "Application";
      categories = [ "Development" ];
    };
  };
}
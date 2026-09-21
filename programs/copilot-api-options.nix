{ lib, ... }: {
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

    # CAUTION: This is used outside this as well for clients to determine how to connect
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
}
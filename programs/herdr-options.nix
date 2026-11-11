{ lib, ... }: {
  options.custom.herdr.plannotator = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Install Plannotator integration for herdr.
        Enables the annotate plugin, the Copilot plan-review detection override,
        and the wrapped Plannotator package.
      '';
    };

    # WARNING: Currently broken! The plugin tries to use a pre-built versisn of Electron,
    #          but a patched version of it thru Nix (e.g. patched Chromium) is required.
    #          It hasn't been setup yet.
    terminalBrowser.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open Plannotator reviews in terminal-browser inside the current herdr workspace.
        Requires custom.herdr.plannotator.enable.
        Each workspace keeps one terminal-browser tab and reuses it for later reviews.
      '';
    };
  };

  options.custom.herdr.bridge = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Route Plannotator reviews and editor requests to the herdr client that is viewing the session.
        Attach with --remote (or the wrapper-only --ssh) through the herdr-bridge wrap command (aliased as herdr) so the client can claim requests
        and open the browser or editor on its own machine. Requires custom.herdr.plannotator.enable for reviews.
      '';
    };

    claimTimeout = mkOption {
      type = types.ints.positive;
      default = 3;
      description = "Seconds a request waits for a wrapped client to claim it before falling back.";
    };

    editor = {
      default = mkOption {
        type = types.enum [ "zed" "code" ];
        default = "zed";
        description = "Editor opened by the default editor keybinding. Resolved on the viewing client, not the server.";
      };

      alt = mkOption {
        type = types.enum [ "zed" "code" ];
        default = "code";
        description = "Editor opened by the alt editor keybinding. Resolved on the viewing client, not the server.";
      };
    };

    keys = {
      edit = mkOption {
        type = types.str;
        default = "prefix+e";
        description = "Keybinding that opens the current pane's workspace in the default editor.";
      };

      editAlt = mkOption {
        type = types.str;
        default = "prefix+shift+e";
        description = "Keybinding that opens the current pane's workspace in the alt editor.";
      };
    };

    aliasHerdr = mkOption {
      type = types.bool;
      default = true;
      description = "Alias `herdr` to `herdr-bridge wrap` in zsh and bash. All arguments pass through to the real herdr; the bridge only engages when `--remote` is given.";
    };

    janitor = {
      interval = mkOption {
        type = types.str;
        default = "15min";
        description = "How often the herdr-bridge janitor timer runs (systemd time span).";
      };

      pendingMaxAge = mkOption {
        type = types.ints.positive;
        default = 3600;
        description = "Seconds a pending request may wait before the janitor checks whether it is still resolvable.";
      };

      claimStaleAfter = mkOption {
        type = types.ints.positive;
        default = 300;
        description = "Seconds after which an unacknowledged claim is treated as abandoned and re-pended or removed.";
      };
    };
  };
}

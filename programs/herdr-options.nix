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
}

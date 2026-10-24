{ pkgs, misc, lib, config, ... }: {
  programs.herdr = {
    enable = true;
    # Settings aren't read-only, only the settings specified below will be overwritten,
    # and only on activation.
    mutableSettings = true;
    # See https://herdr.dev/docs/config-reference/
    settings = {
      experimental = {
        # put all pain history in the session so it can be restored
        pane_history = true;
      };
      theme = {
        name = "terminal";
      };
      ui = {
        toast = {
          # system notifications
          delivery = "system";
        };
        status_indicators = "symbols";
      };
      update = {
        # tells you if there's a new version available
        version_check = true;
      };
    };
  };

  # Needs to be after compinit is initialized
  programs.zsh.initContent = lib.mkMerge [ (lib.mkOrder 1000 (lib.concatLines [
    ''
      eval "$(herdr completion zsh)"
    ''
  ]))];

  programs.bash.initExtra = lib.concatLines [
    ''
    eval "$(herdr completion bash)"
    ''
  ];
}
{ pkgs, misc, lib, config, ... }: {
  programs.herdr = {
    enable = true;
    settings = {
      experimental = {
        # put all pain history in the session so it can be restored
        pane_history = true;
      };
      terminal = {
        kitty_graphics = true;
      };
      theme = {
        name = "terminal";
      };
      ui = {
        toast = {
          # system notifications
          delivery = "system";
          clipboard = {
            enabled = false;
          };
        };
      };
      update = {
        version_check = false;
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
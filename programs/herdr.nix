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
}
{ pkgs, misc, lib, ... }: {

  ## plugins that aren't configured by home-manager
  #home.packages = with pkgs; [
  #  tmuxPlugins.tmux-fzf
  #];

  programs.tmux = {
    enable = true;
    # automatically includes the tmux-sensible plugin, which adapts some common options
    # https://github.com/tmux-plugins/tmux-sensible

    historyLimit = 10000000;
    keyMode = "emacs";
    mouse = true;

    # Allow tmux layouts, startup/exit behaviors, etc to be pre-defined in YAML.
    # Can convert from tmuxinator or teamocil formats if needed
    # https://github.com/tmux-python/tmuxp
    # Capture a current tmux session with:
    #   tmuxp freeze -f yaml -o {pathed_file_name.yaml}
    #  (will need manual correction of processes in the panes. 
    #   Use 'null', 'blank', or 'shell_command:' for panes with default shell
    #   https://github.com/tmux-python/tmuxp)
    #
    tmuxp.enable = true;

    plugins = with pkgs; [
      # tmux-sensible always included automatically

      # uses FZF for interaction
      # https://github.com/sainnhe/tmux-fzf
      tmuxPlugins.tmux-fzf
      # shows the mode (wait, copy, sync, tmux) in the mode line
      # https://github.com/MunifTanjim/tmux-mode-indicator
      tmuxPlugins.mode-indicator
    ];
  };
}

# vim: sw=2:expandtab

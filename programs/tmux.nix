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

      # saves all the pane history, what's currently visible, or everything that's been typed and printed
      # using a key combo trigger
      # https://github.com/tmux-plugins/tmux-logging
      tmuxPlugins.logging

      # Prefix + j activates easyjump mode to jump to an instance of an entered character based on the hint typed
      # https://github.com/schasse/tmux-jump
      tmuxPlugins.jump

      {
        # Prefix + u brings up fzf list of URLs, picking one opens it in the browser
        # https://github.com/wfxr/tmux-fzf-url
        plugin = tmuxPlugins.fzf-tmux-url;
        extraConfig = lib.concatLines [
          ## includes 2000 lines from the scrollback buffer
          #''
          #set  -g @fzf-url-history-limit '2000'
          #''

          # changes fzf config options
          #''
          #set -g @fzf-url-fzf-options 'h-w 50% -h 50% --multi -0 --no-preview --no-border'
          #''
        ];
      }

      {
        # Prefix + ? fuzzy scrollback search for jumping to matched line
        # https://github.com/roosta/tmux-fuzzback
        plugin = tmuxPlugins.fuzzback;
        extraConfig = lib.concatLines [
          ## make it an fzf popup rather than regular fzf
          #''
          #set -g @fuzzback-popup 1
          #''
        ];
      }

      # Prefix + Tab to get fzf fuzzy-searchable list of tokens to paste or copy
      # https://github.com/laktak/extrakto
      tmuxPlugins.extraakto
    ];
  };
}

# vim: sw=2:expandtab

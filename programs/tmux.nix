{ pkgs, misc, lib, ... }: {
  # Requires fzf for most of the plugins

  # extra environment variables
  home.sessionVariables = {
    # tmux-fzf configures most options via environment variables instead

    # Prefix + this to trigger it
    TMUX_FZF_LAUNCH_KEY="f";
    # option choices and ordering.
    # can include session|window|pane|command|keybinding|clipboard|process
    TMUX_FZF_ORDER="window|pane|command|keybinding|session";
  };

  programs.tmux = {
    # default prefix is C-b
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

    extraConfig = lib.concatLines [
      # rebind paste from primary key combo to Prefix + v
      ''
      bind-key -T prefix v paste-buffer -p
      ''
    ];

    plugins = with pkgs; [
      # tmux-sensible always included automatically

      {
        # theme for tmux colors
        # https://github.com/egel/tmux-gruvbox
        plugin = tmuxPlugins.gruvbox;
        extraConfig = lib.concatLines [
          # set theme color to 'light' or 'dark'
          ''
          set -g @tmux-grubox 'dark'
          ''
        ];
      }

      # Prefix + f Uses FZF for command interaction
      # https://github.com/sainnhe/tmux-fzf
      # Most settings are thru TMUX_FZF_ environment variables (see above)
      tmuxPlugins.tmux-fzf

      # Better copy support, including mouse, clipboard, and remote clipboard.
      # https://github.com/tmux-plugins/tmux-yank
      # Copy Mode:
      #   Prefix + y copies to primary, secondary, or clipboard.
      #   Prefix + S-y copies current directory to primary, secondary, or clipboard, and 
      #     immediately exists copy mode and pastes it.
      # Normal Mode:
      #   Prefix + y copies text from command-line primary, secondary, or clipboard
      #   Prefix + S-y copies current working directory to primary, secondary, or clipboard
      # requires wl-copy or xsel to be installed for 'clipboard' option to work
      {
        plugin = tmuxPlugins.yank;
        extraConfig = lib.concatLines [
          # what to copy to when keys are pressed
          # default is 'clipboard'
          ''
          set -g @yank_selection 'primary'
          ''
          # what to copy to when mouse highlights something.
          # default='primary'
          ''
          set -g @yank_selection_mouse 'primary'
          ''
          ## stay in copy mode after yanking instead of leaving it (default='copy-pipe-and-cancel')
          #''
          #set -g @yank_action 'copy-pipe'
          #''
        ];
      }

      {
        # shows the mode (wait, copy, sync, tmux) in the mode line
        # https://github.com/MunifTanjim/tmux-mode-indicator
        plugin = tmuxPlugins.mode-indicator;
        extraConfig = lib.concatLines [
          # requires manually adding '#{tmux_mode_indicator}' to either status-left or status-right,
          # replicating what's already there, in order to do anything
          # Use 'tmux show-options -g | grep status' to see what the current values are
          ''
          set -g status-left '#{tmux_mode_indicator} [#{session_name}]'
          ''
          # override the normal mode indicator text (normally ' TMUX ').
          # all of them are 4 characters, so maintain width.
          ''
          set -g @mode_indicator_empty_prompt '      '
          ''
        ];
      }

      # saves all the pane input/output (prefix + M-S-p), what's currently visible (Prefix + M-p),
      # start/stop logging everything (Prefix + S-p), or clear pane history (Prefix + M-c)
      # using a key combo trigger
      # https://github.com/tmux-plugins/tmux-logging
      tmuxPlugins.logging

      # Prefix + j activates easyjump mode and auto-enters copy mode
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

          # changes fzf config options.  Does not use default fzf display options.
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
          # set the keybinding
          ''
          set -g @fuzzback-bind 'C-f'
          ''
          # make it an fzf popup rather than regular fzf
          ''
          set -g @fuzzback-popup 1
          ''
          # set the popup size (limit it)
          ''
          set -g @fuzzback-popup-size '20%'
          ''
          ## reverse so entry is at the top and selection is top-down instead
          #''
          #set -g @fuzzback-finder-layouer 'reverse'
          #''
        ];
      }

      {
        # Prefix + Tab to get fzf fuzzy-searchable list of tokens to paste or copy
        # https://github.com/laktak/extrakto
        plugin = tmuxPlugins.extrakto;
        extraConfig = lib.concatLines [
          # configure what content to grab for parsing
          # "recent" (visible), "full" pane's history, "window recent" (all windows'
          # visible areas), "window full" (all current windows' panes' history),
          # or any of the options followed by a number to limit the scrollback from
          # the relevant panes to the specified limit.
          # Default = "window full"
          ''
          set -g @extrakto_grab_area 'window recent'
          ''
          ## configure filter type availability and order, with first being default.
          ## Options are: word, line, path, url, quote, s-quote, all
          ## Default = word all line
          #''
          #set -g @extrakto_filter_order 'word all line'
          #''
        ];
      }
    ];
  };
}

# vim: sw=2:expandtab

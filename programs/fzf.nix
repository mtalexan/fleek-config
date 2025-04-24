{ pkgs, misc, lib, config, options, ... }: {

  # more of a global variable to set the bindings more clearly, used in some other modules
  options.custom.fzf = with lib; {
    keybindings = mkOption {
      type = types.listOf types.str;
      default = [
        # To bind multiple keys/events to the same action, comma-separate only the key/events, and add the :action part to the last one.
        # This list will be joined on commas automatically when passed to fzf.
        # These override what each specified key/action does relative to the built-in defaults, but do not unmap any other existing
        #  bindings for a newly mapped action.
        # Some special modes may add/override specific bindings relative to this as well.
        "ctrl-/:toggle-preview"
        "alt-bs:backward-kill-word"
        "alt-j:backward-char"
        "alt-l:forward-char"
        "alt-i:up"
        "alt-k:down"
        "alt-J:backward-word"
        "alt-L:forward-word"
        "alt-I:page-up"
        "alt-K:page-down"
        "ctrl-g:cancel"
        "alt-u:beginning-of-line"
        "alt-o:end-of-line"
        "ctrl-n:next-history"
        "ctrl-p:previous-history"
        "ctrl-]:jump"
        "alt-space,ctrl-space:toggle-in"
        "ctrl-alt-i,alt-up:preview-up"
        "ctrl-alt-k,alt-down:preview-down"
        "ctrl-alt-I:preview-page-up"
        "ctrl-alt-K:preview-page-down"
      ];
      description = ''
        List of key bindings to actions for FZF. Affects both FZF_DEFAULT_OPTS and fzf-tab zsh plugin.
        FZF limits the possible keys to a small subset, see the 'man fzf' under 'Available Keys' heading for the list.
        Bindings specified remap what the keys do if they conflict with built-in defaults, but do not change existing
        bindings for the same actions otherwise.
      '';
    };
    dirPreviewCmd = mkOption {
      type = types.str;
      default = "eza --tree -L 2 --color=always {}";
      description = ''
        Command to use for the preview of a directory.  The {} will be replaced with the selected directory.
        This is used for the fzf-cd-widget and fzf-cd-args-widget functions.
      '';
    };
    filePreviewCmd = mkOption {
      type = types.str;
      default = "bat -n --color=always -r :500 {}";
      description = ''
        Command to use for the preview of a file.  The {} will be replaced with the selected file.
        This is used for the fzf-file-widget and fzf-file-args-widget functions.
      '';
    };
  };

  config = {
    # Alt+C for sub-dir fuzzy search and jump (with preview using eza)
    # Ctrl+T for file fuzzy search and jump (with preview using bat)
    # fuzzy completion for some commmands by using '**' as the arg and then Tab. i.e.:
    #   kill -9 **<tab>
    #   ssh **<tab>
    programs.fzf = {
      enable = true;
      # Turn these on because things that replace the built-in fzf shell completion use them too.
      # By default they're garbage that implement a completely separate completion system and only triggers on things ending in '**'.
      enableBashIntegration = true;
      enableZshIntegration = true;
      defaultCommand = lib.concatStringsSep " " [
        "fd"
        "--type f"
        "--hidden"
        "--follow"
        "--exclude '.git'"
        "."
      ];
      defaultOptions = [
        #"--layout=default"
        # ergo-key bindings using alt
        # WARNING: make sure these are also copied to programs/zsh.nix for the fzf-tab bindings of the zstyle '*:fzf-tab:*:fzf-bindings'
        "--bind '${lib.concatStringsSep "," config.custom.fzf.keybindings}'"
        "--border=sharp"
        "--info=inline"
        "--height=30%"
        "--min-height=10"
        "--layout=reverse"
        "--ansi"
        "--tabstop=4"
        "--color=dark"
        "--cycle"
      ];
      # Alt+C command, look for directories
      changeDirWidgetCommand = lib.concatStringsSep " " [
        "fd"
        "--type d"
        "--hidden"
        "--follow"
        "--exclude '.git'"
        "."
      ];
      changeDirWidgetOptions = [
        "--preview '${config.custom.fzf.dirPreviewCmd}'"
        "--preview-window right,border-vertical"
        "--bind 'ctrl-/:toggle-preview'"
        "--scheme=path"
        "--filepath-word"
        "--multi"
      ];
      # Ctrl+T command, look for files
      fileWidgetCommand = lib.concatStringsSep " " [
        "fd"
        "--type f"
        "--hidden"
        "--follow"
        "--exclude '.git'"
        "."
      ];
      fileWidgetOptions = [
        "--preview '${config.custom.fzf.filePreviewCmd}'"
        "--preview-window right,border-vertical"
        "--bind 'ctrl-/:toggle-preview'"
        "--scheme=path"
        "--filepath-word"
        "--multi"
      ];
    };

    # default priority, formerly initExtra
    programs.zsh.initContent = lib.mkMerge [ (lib.mkOrder 1000 (lib.concatLines [
      # the fzf-file-widget and fzf-cd-widget don't take arguments like the fzf-history-widget does.
      # The technique used by the fzf-history-widget is to add the '--query="$@"' to the FZF_DEFAULT_OPTS.
      # Since we have FZF_DEFAULT_OPTS defined and aren't relying on built-in defaults when FZF_DEFAULT_OPTS is blank,
      # we can use the same technique via custom functions.
      # WARNING: The space after the name and before the '()' is CRITICAL for zle widgets.  It will cause all kinds of weird
      #          problems if you forget it when also using 'zle -n <name>'
      ''
        fzf-file-args-widget () {
          if [ $# -gt 0 ]; then
            FZF_DEFAULT_OPTS+=" --query='$@'"
          fi
          fzf-file-widget
          return $?
        }
        zle -N fzf-file-args-widget

        fzf-cd-args-widget () {
          if [ $# -gt 0 ]; then
            FZF_DEFAULT_OPTS+=" --query='$@'"
          fi
          fzf-cd-widget
          return $?
        }
        zle -N fzf-cd-args-widget
      ''
    ]))];

    programs.bash.initExtra = lib.concatLines [
      # the fzf-file-widget and __fzf_cd__ don't take arguments like the __fzf_history__ does.
      # The technique used by the __fzf_history__ is to add the '--query="$@"' to the FZF_DEFAULT_OPTS.
      # Since we have FZF_DEFAULT_OPTS defined and aren't relying on built-in defaults when FZF_DEFAULT_OPTS is blank,
      # we can use the same technique via custom functions.
      ''
        fzf-file-args-widget() {
          if [ $# -gt 0 ]; then
            FZF_DEFAULT_OPTS+=" --query='$@'"
          fi
          # doesn't follow bash naming convention, the name was copied from the zsh code
          fzf-file-widget
          return $?
        }

        fzf-cd-args-widget() {
          if [ $# -gt 0 ]; then
            FZF_DEFAULT_OPTS+=" --query='$@'"
          fi
          __fzf_cd__
          return $?
        }
      ''
    ];

    # make sure the new function names for passing args to the cd- and files-widgets are the same for bash and zsh so we
    # can set this alias generically.
    home.shellAliases = {
      z = "fzf-cd-args-widget";
    };
  };
}

# vim: ts=2:sw=2:expandtab

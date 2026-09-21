{ pkgs, misc, lib, config, options, ... }: {
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
        "--no-ignore-vcs"
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
      # Ctrl+R command, history
      historyWidget = {
        # disables the Ctrl+R binding when set to empty string
        command = "";
      };
      # Alt+C command, look for directories
      changeDirWidget = {
        command = lib.concatStringsSep " " [
          "fd"
          "--type d"
          "--hidden"
          "--no-ignore-vcs"
          "--follow"
          "--exclude '.git'"
          "--strip-cwd-prefix"
          "."
        ];
        options = [
          "--preview '${config.custom.fzf.dirPreviewCmd}'"
          "--preview-window right,border-vertical"
          # take selected match and keep searching
          "--bind 'ctrl-/:replace-query'"
          "--scheme=path"
          "--filepath-word"
        ];
      };
      # Ctrl+T command, look for files
      fileWidget = {
        command = lib.concatStringsSep " " [
          "fd"
          "--type f"
          "--hidden"
          "--no-ignore-vcs"
          "--follow"
          "--exclude '.git'"
          "--strip-cwd-prefix"
          "."
        ];
        options = [
          "--preview '${config.custom.fzf.filePreviewCmd}'"
          # default to hidden, use the global alt-/ to show it
          "--preview-window right,border-vertical,hidden"
          "--scheme=path"
          "--filepath-word"
          "--multi"
        ];
      };
    };

    # default priority, formerly initExtra
    programs.zsh = {
      initContent = lib.mkMerge [ (lib.mkOrder 1000 (lib.concatLines [
        # the fzf-file-widget and fzf-cd-widget don't take arguments like the fzf-history-widget does.
        # The technique used by the fzf-history-widget is to add the '--query="$@"' to the FZF_DEFAULT_OPTS.
        # Since we have FZF_DEFAULT_OPTS defined and aren't relying on built-in defaults when FZF_DEFAULT_OPTS is blank,
        # we can use the same technique via custom functions.
        # WARNING: The space after the name and before the '()' is CRITICAL for zle widgets.  It will cause all kinds of weird
        #          problems if you forget it when also using 'zle -n <name>'
        ''
          # Cannot be called as a shell function, this is a widget that can be bound to a key.
          fzf-file-args-widget () {
            if (( $# > 0 )); then
              FZF_DEFAULT_OPTS+=" --query='$*'"
            fi
            zle fzf-cd-widget
            return $?
          }
          zle -N fzf-cd-args-widget
  
          # callable shell function version of fzf-file-args-widget that can be called from the command-line
          fzf-file-args-cmd () {
            # Set a global pre-defined temp variable to hold the FZF options we should use
            typeset -g _TMP_FZF_EXTRA_DEFAULT_OPTS=""
            if (( $# > 0 )); then
              _TMP_FZF_EXTRA_DEFAULT_OPTS+=" --query='$*'"
            fi
  
            # Wrapper for the FZF provided fzf-file-widget that can be defined and registered
            # as a line-init hook, but auto-removes itself and cleans up the global temp variable
            _fzf-file-widget-once () {
              # de-register ourselves as a line-init hook and as a widget for future calls.
              add-zle-hook-widget -d line-init _fzf-file-widget-once
              zle -D _fzf-file-widget-once
    
              # Locally override this global variable, adding the extra values.
              # The widget doesn't use the FZF_DEFAULT_OPTS, it uses FZF_CTRL_T_OPTS.
              local -x FZF_CTRL_T_OPTS+="$_TMP_FZF_EXTRA_DEFAULT_OPTS"
              unset _TMP_FZF_EXTRA_DEFAULT_OPTS
    
              # call the FZF provided widget as a widget
              zle fzf-file-widget
            } 
  
            # register our custom widget to run on the next prompt initialization.
            # That widget de-registers itself automatically.
            zle -N _fzf-file-widget-once
            add-zle-hook-widget line-init _fzf-file-widget-once
          }
          
          fzf-cd-args-widget () {
            if (( $# > 0 )); then
              FZF_DEFAULT_OPTS+=" --query='$*'"
            fi
            fzf-cd-widget
            return $?
          }
          zle -N fzf-cd-args-widget
  
          # callable shell function version of fzf-file-args-widget that can be called from the command-line
          fzf-cd-args-cmd () {
            # Set a global pre-defined temp variable to hold the FZF options we should use
            typeset -g _TMP_FZF_EXTRA_DEFAULT_OPTS=""
            if (( $# > 0 )); then
              _TMP_FZF_EXTRA_DEFAULT_OPTS+=" --query='$*'"
            fi
  
            # Wrapper for the FZF provided fzf-file-widget that can be defined and registered
            # as a line-init hook, but auto-removes itself and cleans up the global temp variable
            _fzf-cd-widget-once () {
              # de-register ourselves as a line-init hook and as a widget for future calls.
              add-zle-hook-widget -d line-init _fzf-cd-widget-once
              zle -D _fzf-cd-widget-once
    
              # locally override this global variable, adding the extra values.
              # The widget doesn't use the FZF_DEFAULT_OPTS, it uses FZF_ALT_C_OPTS.
              local -x FZF_ALT_C_OPTS+="$_TMP_FZF_EXTRA_DEFAULT_OPTS"
              unset _TMP_FZF_EXTRA_DEFAULT_OPTS
    
              # call the FZF provided widget as a widget
              zle fzf-cd-widget
            } 
  
            # register our custom widget to run on the next prompt initialization.
            # That widget de-registers itself automatically.
            zle -N _fzf-cd-widget-once
            add-zle-hook-widget line-init _fzf-cd-widget-once
          }
        ''
      ]))];

      shellAliases = {
        # zsh-only alias, since fzf-cd-args-cmd is a zle-based function defined only in the zsh init.
        z = "fzf-cd-args-cmd";
      };
    };

    # No possible equivalent for callable wrapper in bash, and no way to use a bash widget that takes arguments.
  };
}

# vim: ts=2:sw=2:expandtab

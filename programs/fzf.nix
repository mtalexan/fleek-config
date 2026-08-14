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
        "alt-/:toggle-preview"
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
        # ctrl-enter isn't allowed
        "alt-space,ctrl-space,alt-enter:toggle"
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

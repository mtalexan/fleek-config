{ lib, ... }: {
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
}
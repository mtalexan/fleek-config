{ pkgs, misc, lib, ... }: {
  # Alt+C for sub-dir fuzzy search and jump (with preview using eza)
  # Ctrl+T for file fuzzy search and jump (with preview using bat)
  # fuzzy completion for some commmands by using '**' as the arg and then Tab. i.e.:
  #   kill -9 **<tab>
  #   ssh **<tab>
  programs.fzf = {
    enable = true;
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
      "--bind 'ctrl-/:toggle-preview,alt-bs:backward-kill-word,alt-j:backward-char,alt-l:forward-char,alt-i:up,alt-k:down,alt-J:backward-word,alt-L:forward-word,alt-I:page-up,alt-K:page-down,ctrl-g:cancel,alt-u:beginning-of-line,alt-o:end-of-line,ctrl-n:next-history,ctrl-p:previous-history,ctrl-]:jump,alt-space:toggle-in,ctrl-space:toggle-in,ctrl-alt-k:preview-down,ctrl-alt-i:preview-up,ctrl-alt-I:preview-page-up,ctrl-alt-K:preview-page-down'"
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
      "--preview 'eza --tree -L 2 --color=always {}'"
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
      "--preview 'bat -n --color=always -r :500 {}'"
      "--preview-window right,border-vertical"
      "--bind 'ctrl-/:toggle-preview'"
      "--scheme=path"
      "--filepath-word"
      "--multi"
    ];
  };

  programs.zsh.initExtra = lib.concatLines [
    # the fzf-file-widget and fzf-cd-widget don't take arguments like the fzf-history-widget does.
    # The technique used by the fzf-history-widget is to add the '--query="$@"' to the FZF_DEFAULT_OPTS.
    # Since we have FZF_DEFAULT_OPTS defined and aren't relying on built-in defaults when FZF_DEFAULT_OPTS is blank,
    # we can use the same technique via custom functions.
    ''
      fzf-file-args-widget() {
        if [ $# -gt 0 ]; then
          FZF_DEFAULT_OPTS+="--query='$@'"
        fi
        fzf-file-widget
        return $?
      }

      fzf-cd-args-widget() {
        if [ $# -gt 0 ]; then
          FZF_DEFAULT_OPTS+="--query='$@'"
        fi
        fzf-cd-widget
        return $?
      }
    ''
  ];

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
}

# vim: sw=2:expandtab

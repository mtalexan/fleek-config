{ pkgs, misc, lib, ... }: {
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
    # Ctrl+T command
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
}

# vim: sw=2:expandtab

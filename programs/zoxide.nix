{ pkgs, misc, lib, ... }: {
  # 'z' and 'zi' commands for directory jumps based on frecency.  
  # Uses fzf to select options if using 'z <pattern> '+tab
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # options to pass to the 'zoxide init' command
    options = [
      # update directory scores on every folder change
      "--hook=pwd"
      # replace the cd command with zoxide if set.  Default is 'z' and 'zi'
      #"--cmd=cd"
    ];
    # The following environment variables have to be set manually in the home.sessionVariables if needed
    # _ZO_ECHO = 1 ; to print matched dir before jumping
    # _ZO_EXCLUDE_DIRS = dir:dir:dir ; list of ':' separated dirs to ignore
    # _ZO_FZF_OPTS = <opts>; options to pass to fzf when opening it for match selection
    # _ZO_MAXAGE = 10000; maximum number of entries in the database
    # _ZO_RESOLVE_SYMLINKS = 1; to resolve symlinks before adding to the database
  };

  # shared shell settings
  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
    # use options like FZF changeDir (Alt+C) display options
    _ZO_FZF_OPTS = lib.concatStringsSep " " [
      # 'zoxide -i' always passes the score then the folder name with some leading indentation.
      # Carefully echo the string, parse it thru awk to get only the second column, and then use
      # the result in an eza --tree command that shows colors and only 2 dirs deep in each tree
      "--preview 'eza --tree -L2 --color=always \\$( echo {} | awk '\\''{ print \\$2 }'\\'')'"
      "--preview-window right,border-vertical" 
      "--bind 'ctrl-/:toggle-preview'"
      "--scheme=path"
      "--filepath-word"
      "--multi" 
      "--info=inline"
      "--border=sharp" 
      # let it be taller than fzf history, but not fullscreen like changeDir
      "--height=50%" 
      "--tabstop=4" 
      "--color=dark" 
      "--cycle" 
      "--layout=reverse"
    ];
  };
}

# vim: sw=2:expandtab

{ pkgs, misc, lib, ... }: {
  # NOT USED: doesn't really work
  #
  # A rust-based attempt to be like z.lua, but missing all the useful functionality from it.
  # Instead it's a global path frecency jump tool that pays no attention to the current folder.
  # It also uses clock-time for frecency, unlike z.lua.
  #
  # It wants to use a 'z' and 'zi' alias, but since it doesn't actually do what z.lua does (that already use thes),
  # we need to block these mappings.
  # It uses fzf for interactive search.
  #
  # Implemented mapping is to provide 'za' as an interactive fzf lookup.
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # options to pass to the 'zoxide init' command
    options = [
      # update directory scores on every prompt redraw ('prmopt') instead of only when dir is changed ('pwd').
      # clock time is used to degrade frecency, so for a global lookup list we want to know if we were
      # running a bunch of commands in one directory for an extended period of time.
      "--hook=prompt"
      # Command to trigger the function. If set to 'cd' it will replace the cd command.
      # Default is 'z' and 'zi' (interactive)
      #"--cmd=cd"
      # don't add any commands, custom commands/aliases will need to use __zoxide_z and __zoxide_zi
       "--no-cmd"
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
  programs.bash.shellAliases = {
    # custom command alias to do interactive global frecency search. Args are passed to the function
    za = "__zoxide_zi";
  };
  programs.zsh.shellAliases = {
    # custom command alias to do interactive global frecency search. Args are passed to the function
    za = "__zoxide_zi";
  };
}

# vim: ts=2:sw=2:expandtab

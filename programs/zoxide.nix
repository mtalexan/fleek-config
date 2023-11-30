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
    # The following environment variables have to be set manually in the home.sessionVariables
    # _ZO_ECHO = 1 ; to print matched dir before jumping
    # _ZO_EXCLUDE_DIRS = dir:dir:dir ; list of ':' separated dirs to ignore
    # _ZO_FZF_OPTS = <opts>; options to pass to fzf when opening it for match selection
    # _ZO_MAXAGE = 10000; maximum number of entries in the database
    # _ZO_RESOLVE_SYMLINKS = 1; to resolve symlinks before adding to the database
  };
}

# vim: sw=2:expandtab

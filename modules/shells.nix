{ pkgs, misc, lib, ... }: {
  # Settings for the different shells go in here

  imports = [
    ../programs/bash.nix
    ../programs/zsh.nix
  ];

  # shared shell settings
  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
    GCC_COLORS = "error=01;31;warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };
}

# vim: sw=2:expandtab

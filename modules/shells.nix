{ pkgs, misc, lib, ... }: {
  # Settings for the different shells go in here

  imports = [
    ../programs/bash.nix
    ../programs/zsh.nix
  ];

   home.shellAliases = {
    "bathelp" = "bat --plain --language=help";
    "batpretty" = "prettybat";
    "cat" = "bat";
    "catp" = "bat -P";
    # runs a custom shell script named fleek-apply
    "fleek-impure" = "fleek-apply --impure";
    # Also see fleek-update, which is a directly callable script
    "fleeks" = "cd ~/.local/share/fleek";
    "gbc" = "git branch --show-current";
    "gbvv" = "git branch -vv";
    "gcm" = "git commit";
    "gd" = "git diff";
    "gdc" = "git diff --cached";
    "glg" = "git log --oneline --decorate --graph";
    "gs" = "git status";
    "la" = "eza -a";
    "ll" = "eza -l";
    "lla" = "eza -l -a";
    "llag" = "eza -l -a --git";
    "llg" = "eza -l --git";
    "ls" = "eza";
    "lt" = "eza --tree";
    "rgfzf" = "sd rg-fzf";
    "tree" = "eza --tree";
  };

  # shared shell settings
  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
    GCC_COLORS = "error=01;31;warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };
}

# vim: sw=2:expandtab

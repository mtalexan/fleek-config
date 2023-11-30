{ pkgs, misc, lib, ... }: {
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}

# vim: sw=2:expandtab

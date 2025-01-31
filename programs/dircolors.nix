{ pkgs, misc, lib, ... }: {
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}

# vim: ts=2:sw=2:expandtab

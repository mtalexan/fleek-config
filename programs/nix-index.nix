{ pkgs, misc, lib, ... }: {
  # supplies the command-not-found hook to tell about nix packages
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}

# vim: ts=2:sw=2:expandtab

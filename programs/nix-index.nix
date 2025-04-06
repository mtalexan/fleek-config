{ pkgs, misc, lib, ... }: {
  # Supplies the command-not-found hook to tell about nix packages.
  # Also supports nix-locate to look for which package provides a file name.

  # When nix-index-database home-manager module is installed, programs.nix-index configures use of that.
  # When using the wrapper, do NOT include 'home.programs = [ pkgs.nix-index ];'

  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # undocumented option that puts the cache in the ~/.cache location
    symlinkToCacheHome = true;
  };
}

# vim: ts=2:sw=2:expandtab

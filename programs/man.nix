{ pkgs, misc, lib, ... }: {
  # also adds the man pages for home-manager
  programs.man = {
    enable = true;
    # a bit slower when home-manager creates new generations, but helpful
    generateCaches = true;
  };
}

# vim: sw=2:expandtab

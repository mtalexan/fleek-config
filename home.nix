{ config, pkgs, misc, ... }: {
  # This file is for home-manager config only.
  # For historical (non-flake) reasons, it's called home.nix.

  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };
  manual = {
    # This causes an error, so disable it
    ## adds a home-manager-helper command that opens a web page of the options
    #html.enable = true;
    # adds 'man home-manager.nix'
    manpages.enable = true;
  };

  # silent, notify, or show
  news.display = "notify";

  # Extra outputs of the home.packages that should be installed
  home.extraOutputsToInstall = [
    "doc"
    "info"
    "devdoc"
  ];

  fonts.fontconfig = {
    # add nix fonts to the system fontconfig
    enable = true;
  };
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;
}

# vim: ts=2:sw=2:expandtab

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

  # A user systemd service to automatically clean up old home-manager generations.
  # It can also do nix store automatic cleanup as well
  services.home-manager.autoExpire = {
    enable = true;
    # how often to run the cleanup check
    frequency = "weekly"; # see systemd.timer syntax
    # how old of generations to clean up
    timestamp = "-7 days"; # see 'date' tool '-d' syntax
    store = {
      cleanup = true;
      # Extra options to the nix-collect-garbage command.
      # It already cleans up unreachable packages, but using --delete-old or --delete-older-than= can
      # also have it cleanup unused profiles as well.
      options = "--delete-old";
    };
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

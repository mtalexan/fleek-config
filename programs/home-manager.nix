{ pkgs, misc, lib, inputs, ... }: {
  # Various settings for home-manager itself
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
}

# vim: sw=2:expandtab

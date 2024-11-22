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

  # Integrate nixGL into the home-manager. See: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
  # See the per-system custom.nix files for the nixGL configuration options per-system
  # Fleek sets up the input flakes weird so they're passed under inputs and not remapped to a nicer name.
  nixGL.packages = inputs.nixgl.packages;
}

# vim: sw=2:expandtab

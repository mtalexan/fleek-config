{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default git identity
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # Host Specific username and home location
    home.username = "mike";
    home.homeDirectory = "/home/mike";
    # where to find the git SSH key on this system
    programs.git.signing.key = "~/.ssh/id_ed25519_github";

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    #home.packages = [
    #];

    #####################################
    # Custom defined config settings
    #####################################

    custom.nixGL.gpu = false;

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim:sw=2:expandtab

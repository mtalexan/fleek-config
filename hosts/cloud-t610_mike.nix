{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default identities and secrets
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {
    # Host Specific username and home location
    home.username = "mike";
    home.homeDirectory = "/home/${config.home.username}";

    # see below in the custom.git_keys for the git SSH key setup

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    #home.packages = [
    #];

    #####################################
    # Custom defined config settings
    #####################################

    custom = {
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";

      # the identity/*.nix file uses these to set the global git signing.key (to the personal value), and
      # populate the git-identity config keys.  Personal is mandatory.
      git_keys = {
        personal = "${config.home.homeDirectory}/.ssh/id_ed25519_github";
      };
    };

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim: ts=2:sw=2:expandtab
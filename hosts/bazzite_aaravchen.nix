{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default identities and secrets
    ../modules/fedora_shells.nix
    ../programs/distrobox.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
  ];
  
  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {

    # Host Specific username and home location
    home.username = "aaravchen";
    home.homeDirectory = "/var/home/${config.home.username}";

    # see below in the custom.git_keys for the git SSH key setup

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
    ];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";
      
      # let it default to iGPU (lightweight) even though there's a dGPU in the system
      nixGL.has_dgpu = true;

      # the identity/*.nix file uses these to set the global git signing.key (to the personal value), and
      # populate the git-identity config keys.  Personal is mandatory.
      git_keys = {
        personal = "${config.home.homeDirectory}/.ssh/github_ed25519";
      };

      # The primary distrobox config file
      distrobox = {
        hooks = {
          enable = true;
          docker_sock = true;
        };
      };
    };

    #####################################
    # One-off Program Settings
    #####################################

    home.shellAliases = {
      # end all aliases in a space so completion on arguments works for them

      # Flatpaks
      "meld" = "flatpak run org.gnome.meld ";
    };
  };
}

# vim: ts=2:sw=2:expandtab

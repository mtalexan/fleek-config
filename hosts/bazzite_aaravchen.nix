{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default git identity
    ../modules/fedora_shells.nix
    ../programs/distrobox.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for construcing absolute paths to files.
  config = rec {

    # Host Specific username and home location
    home.username = "aaravchen";
    home.homeDirectory = "/var/home/${config.home.username}";
    # where to find the git SSH key on this system
    programs.git.signing.key = "${config.home.homeDirectory}/.ssh/github_ed25519";

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    #home.packages = [
    #];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      nixGL.gpu = false;

      # The primary distrobox config file
      distrobox.hooks = {
        enable = true;
        docker_sock = true;
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
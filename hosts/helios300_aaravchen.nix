{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default git identity
    #../modules/fedora_shells.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    # vscode is provided by the system
  ];


  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # Host Specific username and home location
    home.username = "aaravchen";
    home.homeDirectory = "/home/aaravchen";
    # where to find the git SSH key on this system
    programs.git.signing.key = "~/.ssh/github_ed25519";

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    #home.packages = [
    #];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      # the GPU doesn't always appear as available because it uses NvidiaPrime, so disable this to avoid build errors when it's not visible.
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


# vim:sw=2:expandtab

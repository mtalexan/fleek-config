{ pkgs, misc, ... }: {
  imports = [
    ../modules/fedora_shells.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {

    # Host Specific username and home location
    home.username = "aaravchen";
    home.homeDirectory = "/home/aaravchen";

    # Host-specific default git settings.  Expanded on in the modules/git.nix and programs/git.nix
    programs.git = {
      # optional override uniquely for the host
      #userName = "Mike";
      #userEmail = "github@trackit.fe80.email";

      # SSH default signing key location
      signing = {
          key = "~/.ssh/github_ed25519";
          signByDefault = builtins.stringLength "~/.ssh/github_ed25519" > 0;
      };
    };

    # extra packages that should be installed only on this host
    home.packages = [
      pkgs.distrobox
    ];

    #####################################
    # Files (arbitrary)
    #####################################

    # The primary distrobox config file
    custom.distrobox.hooks = {
      enable = true;
      docker_sock = true;
    };

    #####################################
    # Programs
    #####################################

    home.shellAliases = {
      # end all aliases in a space so completion on arguments works for them

      # Flatpaks
      "meld" = "flatpak run org.gnome.meld ";
    };
  };
}


# vim:sw=2:expandtab

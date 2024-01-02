{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  imports = [
    ../modules/fedora_shells.nix
    ../programs/terminator.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
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
      "code" = "flatpak run com.visualstudio.code ";
      "meld" = "flatpak run org.gnome.meld ";
      "wireshark" = "flatpak run org.wireshark.Wireshark ";
    };
  };
}


# vim:sw=2:expandtab

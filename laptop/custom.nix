{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  imports = [
    ../modules/fedora_shells.nix
    ../programs/terminator.nix
    ../programs/distrobox.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
<<<<<<< Updated upstream
    custom.nixGL.gpu = false;

    # extra packages that should be installed only on this host
    #home.packages = [
    #];
||||||| Stash base
    # extra packages that should be installed only on this host
    home.packages = [
      pkgs.distrobox
    ];
=======
>>>>>>> Stashed changes

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
  };
}

# vim:ts=2;sw=2


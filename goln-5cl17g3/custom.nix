{ pkgs, misc, lib, config, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  imports = [
    ../programs/terminator.nix
    ../programs/kitty.nix
    # just adds an existing install to the PATH
    ../programs/homebrew.nix
    # just adds an existing install to the PATH
    ../programs/rustup.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # extra packages that should be installed only on this host
    home.packages = [
      pkgs.distrobox
      pkgs.rename
      # don't use podman or skopeo from nix,
      # podman is suddenly experiencing a bug where 'podman run --userns:keep-id ...' isn't properly linking
      #   the overlay folders together and fails to start any containers.
      # skopeo wasn't built with glibc-static and CGO, so it can't parse users or groups from LDAP.
    ];

    #####################################
    # Files (arbitrary)
    #####################################

    # The primary distrobox config file
    custom.distrobox = {
      hooks = {
        enable = true;
        host_certs = true;
        docker_sock = true;
      };
      config.engine = "docker";
    };

    #####################################
    # Programs
    #####################################

    # add the extra DevTools path, just in case it's there.  If it is, it's relevant
    home.sessionPath = [
      "$HOME/DevTools/bin"
    ];

    programs.bash.initExtra = lib.concatLines [
      ''
      if [ -e "$HOME/DevTools/.bashrc" ] ; then
        source $HOME/DevTools/.bashrc
      fi
      ''
    ];

    #programs.zsh.initExtra = lib.concatLines [
    #];
  };
}

# vim: sw=2:expandtab

{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default git identity
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for construcing absolute paths to files.
  config = rec {
    # Host-specific username and home location
    home.username = "mtalexander";
    home.homeDirectory = "/home/${config.home.username}";
    # location on this specific host where the default signing key is
    programs.git.signing.key = "${config.home.homeDirectory}/.ssh/gitlab_ed25519";
    # the locations of the SSH private keys to use for decrypting age secrets.
    age.identityPaths = [
      "${config.home.homeDirectory}/.ssh/fleek_agecrypt"
    ];

    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
      # don't use podman or skopeo from nix,
      # podman is suddenly experiencing a bug where 'podman run --userns:keep-id ...' isn't properly linking
      #   the overlay folders together and fails to start any containers.
      # skopeo wasn't built with glibc-static and CGO, so it can't parse users or groups from LDAP.
    ];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      nixGL.gpu = true;

      distrobox = {
        hooks = {
          enable = true;
          host_certs = true;
          docker_sock = true;
        };
        config.engine = "docker";
      };
    };

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim: ts=2:sw=2:expandtab

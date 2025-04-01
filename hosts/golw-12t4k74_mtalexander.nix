{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default git identity
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # Host-specific username and home location
    home.username = "mtalexander";
    home.homeDirectory = "/home/mtalexander";
    # the location on this specific machine where the default SSH  key is to use for signing
    programs.git.signing.key = "~/.ssh/gitlab_ed25519";
    programs.atuin.settings = {
      # enable syncing using the E2EE default server
      #auto_sync = true;
      # sync after every command
      sync_frequency = "0";
      #key_path = ;
      #session_path = ;
    }


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

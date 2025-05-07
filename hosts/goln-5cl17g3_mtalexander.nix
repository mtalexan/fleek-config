{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default identities and secrets
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
    ../programs/zed-editor.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {
    # Host-specific username and home location
    home.username = "mtalexander";
    home.homeDirectory = "/home/${config.home.username}";

    # see below in the custom.git_keys for the git SSH key setup

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
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";
      
      # let it default to iGPU (lightweight) even though there's a dGPU in the system
      nixGL.has_dgpu = true;

      # the identity/*.nix file uses these to set the global git signing.key (to the work value), and
      # populate the git-identity config keys.  Personal is optional but work is mandatory for identity/ks.nix.
      git_keys = {
        work = "${config.home.homeDirectory}/.ssh/gitlab_ed25519";
        personal = "${config.home.homeDirectory}/.ssh/github_personal_ed25519";
      };

      distrobox = {
        hooks = {
          enable = true;
          host_certs = true;
          docker_sock = true;
        };
        config.engine = "docker";
      };
      
      # default non-static config for zed using nixpkgs version of zeditor
      zed-editor = {
        external_zed = false; # the default
        static_config = false; # the default
        assistant = "copilot"; # only applies if static_config=true
      };
    };

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim: ts=2:sw=2:expandtab

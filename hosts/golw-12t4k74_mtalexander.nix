{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default identities and secrets
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
    ../programs/zed-editor.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well.
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = rec {
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
      nixGL.gpu = true;

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
    };

    #####################################
    # One-off Program Settings
    #####################################
    home.sessionVariables = {
      # Using Ubuntu KDE that's only X11 still. Set this so all the Wayland-capable
      # tools/libs know to fall back to X11 support instead.
      WAYLAND_DISPLAY = "";
      # Vulkan tools are only available on this host with Wayland support, so Zed only works
      # with GPUs on Wayland for this. Disable the warning pop up on each zed startup about this.
      ZED_ALLOW_EMULATED_GPU = "1";
    };
  };
}

# vim: ts=2:sw=2:expandtab

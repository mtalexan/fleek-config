{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default identities and secrets
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/parallel_kitty.nix
    ../programs/flameshot.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
    # This takes forever to build each time since it requires an impure build for GPU access, which prevents cachix usage.
    #../programs/zed-editor.nix
    # Currently has broken support for NIX_SSL_CERT_FILE and custom Root CA certs from nixpkgs.emacs-unstable
    #../programs/emacs.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well.
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
    # NVIDIA GPU Support
    #####################################
    # If the system GPU is an NVIDIA GPU, the proprietary NVIDIA drivers have
    # to be installed in the Nix config as well that exactly match the version
    # installed on the host. This MUST be kept up to date manually.
    # See https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
    # 
    # Run this to quickly calculate the sha256 to use below, and prepopulate the package in the nix-store:
    # NVIDIA_VER="550.163.01"; nix store prefetch-file https://download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VER}/NVIDIA-Linux-x86_64-${NVIDIA_VER}.run
    #
    targets.genericLinux.gpu.nvidia = {
      enable = true;
      version = "580.126.09";
      sha256 = "sha256-TKxT5I+K3/Zh1HyHiO0kBZokjJ/YCYzq/QiKSYmG7CY=";
    };
    
    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
      # don't use podman or skopeo from nix,
      # podman is suddenly experiencing a bug where 'podman run --userns:keep-id ...' isn't properly linking
      #   the overlay folders together and fails to start any containers.
      # skopeo wasn't built with glibc-static and CGO, so it can't parse users or groups from LDAP.

      # For sharing mouse/keyboard between machines. Requires external manual configuration between the
      # individual machines running it.
      # The Deskflow flatpak doesn't work on Ubuntu 24.04 Wayland due to the libie being too old.
      # This nix install works when run with sudo though, i.e. 'sudo $(which deskflow)'.
      pkgs.deskflow
    ];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";

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
    # WARNING: emacs installed via Nix suffers from an issue on SSSD systems where it's unaware of the SSSD users, so libnss lookups
    #          will get './~$USER' as the users home folder instead of what's correct.  To solve this specifcially for
    #          emacs, we can call 'emacs --user ""' and it works to find the correct home folder.
    home.shellAliases = {
      # make sure we point to our fully-configured emacs package, otherwise it will fallback the underlying non-configured emacs.
      "emacs" = ''${config.programs.emacs.package}/bin/emacs --user "" '';
    };
  };
}

# vim: ts=2:sw=2:expandtab

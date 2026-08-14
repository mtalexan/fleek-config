{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default identities and secrets
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/parallel_kitty.nix
    ../programs/flameshot.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
    ../programs/zed-editor.nix
    ../programs/containers-common.nix # needs enabling of config to make it do anything
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

    # the locations of the SSH private keys to use for decrypting age secrets from secrets/
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
      version = "580.173.02";
      sha256 = "sha256-jY65AB4FqaimY9PV0wT+tk7yhE7hhczf2VJ4aCD0bhs=";
    };
    
    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename

      pkgs.meld

      # For sharing mouse/keyboard between machines. Requires external manual configuration between the
      # individual machines running it.
      # The Deskflow flatpak doesn't work on Ubuntu 24.04 Wayland due to the libie being too old.
      # This nix install works when run with sudo though, i.e. 'sudo $(which deskflow)'.
      pkgs.deskflow
      
      # Include the RPM tools for working with RPM packages
      pkgs.rpm
      # Tools used frequently from the host
      pkgs.shellcheck
      pkgs.shellspec
      pkgs.uv
      
      # The gitlab CLI Tool
      # Not a Home Manager package yet, so we can't auto-configure with identities.
      pkgs.glab
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

      # Age key classes available on this host for chezmoi secret decryption from chezmoi/.chezmoisecrets/*/*.age
      chezmoi = {
        config.age_keys = {
          work = {
            secret_file = "${config.home.homeDirectory}/.age/fleek_chezmoi_work";
            # recipient set in identity file
          };
        };
      
        # the rest of the settings are in the identities files, we just have to set this and include pkgs.glab
        templates.glab.data.enable = true;
      };

      # have to enable podman and skopeo here since our definition has to inject a distribution policy
      # to make them work. 
      containers-common.config = {
        podman = true;
        skopeo = true;
        dist_config = {
          seccomp = true;
          cgroup_manager = "systemd";
        };
        user_config = {
          policy = true;
          storage_driver = "overlay";
        };
      };

      atuin.ai = true;
      
      # Zed editor feature toggles
      zed = {
        gitlab_mcp = {
            enable = true;
            # url is set by the identities/*.nix file and inherited here
        };
        copilot = true;
      };

      distrobox = {
        hooks = {
          enable = true;
          host_certs = true;
          docker_sock = true;
        };
        config.engine = "docker";
      };

      emacs.sssd_workaround = true;
    };

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim: ts=2:sw=2:expandtab

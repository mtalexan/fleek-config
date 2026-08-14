{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default identities and secrets
    # Currently has broken support for NIX_SSL_CERT_FILE and custom Root CA certs from nixpkgs.emacs-unstable
    #../programs/emacs.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {
    # Host Specific username and home location
    home.username = "mike";
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
      version = "580.159.03";
      sha256 = "sha256-MshdmbD2QMlQH2GzndrSCP0CiNAVxPvF/QQ1wHeD+nc=";
    };
    
    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
      pkgs.inxi
    ];

    #####################################
    # Custom defined config settings
    #####################################

    custom = {
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";

      # OpenSUSE uses an unusual location for the bundle
      certs.bundle = "/etc/ssl/ca-bundle.pem";

      # the identity/*.nix file uses these to set the global git signing.key (to the personal value), and
      # populate the git-identity config keys.  Personal is mandatory.
      git_keys = {
        personal = "${config.home.homeDirectory}/.ssh/id_ed25519_github";
      };

      # Age key classes available on this host for chezmoi secret decryption from chezmoi/.chezmoisecrets/*/*.age
      chezmoi.config.age_keys = {
        personal = {
          secret_file = "${config.home.homeDirectory}/.age/fleek_chezmoi_personal";
          # recipient set in identity file
        };
      };
    };

    #####################################
    # One-off Program Settings
    #####################################
  };
}

# vim:sw=2:expandtab

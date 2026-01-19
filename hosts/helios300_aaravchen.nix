{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default identities and secrets
    #../modules/fedora_shells.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
    ../programs/parallel_kitty.nix
    ../programs/flameshot.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
    #../programs/zed-editor.nix
  ];


  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {
    # Host Specific username and home location
    home.username = "aaravchen";
    home.homeDirectory = "/home/${config.home.username}";

    # see below in the custom.git_keys for the git SSH key setup

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
      version = "590.48.01";
      sha256 = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
    };
    
    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
    ];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      # the location of this cloned repo. Also set in env var FLEEK_CONFIG_DIR
      configdir = "${config.home.homeDirectory}/.local/share/fleek";

      # the identity/*.nix file uses these to set the global git signing.key (to the personal value), and
      # populate the git-identity config keys.  Personal is mandatory.
      git_keys = {
        personal = "${config.home.homeDirectory}/.ssh/github_ed25519";
      };

      # The primary distrobox config file
      distrobox = {
        hooks = {
          enable = true;
          docker_sock = true;
        };
        config.engine = "docker";
      };
    };

    #####################################
    # One-off Program Settings
    #####################################

    home.shellAliases = {
      # end all aliases in a space so completion on arguments works for them

      # Flatpaks
      "meld" = "flatpak run org.gnome.meld ";
    };
  };
}


# vim:sw=2:expandtab

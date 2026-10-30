{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    ../identities/personal.nix # set the default identities and secrets
    #../modules/fedora_shells.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
    ../programs/parallel_kitty.nix
    ../programs/flameshot.nix
    ../programs/distrobox.nix
    # vscode is provided by the system, but install it anyway so we get any extra config we need with it
    ../programs/vscode.nix
    ../programs/zed-editor.nix
    #../programs/github-copilot-cli.nix
    #../programs/herdr.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for constructing absolute paths to files.
  config = {
    # Host-specific username and home location
    home.username = "aaravchen2";
    home.homeDirectory = "/var/home/${config.home.username}";

    # see below in the custom.git_keys for the git SSH key setup

    #####################################
    # NVIDIA GPU Support
    #####################################
    
    # No NVIDIA GPU on this system
    
    #####################################
    # Extra host-unique non-configurable packages
    #####################################

    home.packages = [
      pkgs.rename
      pkgs.cosign
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
        personal = "${config.home.homeDirectory}/.ssh/id_ed25519_github";
      };

      # Age key classes available on this host for chezmoi secret decryption from chezmoi/.chezmoisecrets/*/*.age
      chezmoi.config.age_keys = {
        personal = {
          secret_file = "${config.home.homeDirectory}/.age/fleek_chezmoi_personal";
          # recipient set in identity file
        };
      };


      # This says to use shared-mime-info 2.4 from stable nixpkgs instead of the >=2.5 one from unstable nixpkgs.
      # The host and nix must either both be <2.5 or >=2.5. The 2.5 mime database from Freedesktop reversed some MIME type
      # definition dependencies and it causes circular dependency loops if you mix them. Qt is especially sensitive to this
      # and didn't get a fix for it until Qt 6.5. That makes Kubuntu 24.04 (which is Qt5) hang then crash the entire DE
      # constantly when this occurs.
      shared-mime-info.useStable = true;
      
      # skills under ~/.agents/skills/work, encrypted to fleek_chezmoi_personal
      agents = {
        personal = true;
        common = true;
      };

      github-copilot-cli = {
        # maximum number of concurrent chats.
        maxParallel = 8;
        # The Plannotator browser-based tool for reviewing Plans, and enable the /plannotator-review command for reviewing and commenting on changes.
        plannotator.enable = true;
      };

      herdr.plannotator = {
        # Enable the Plannotator plugin that uses the in-browser plugin for annotation of anything.
        enable = true;
        # Use terminal-browser as a tab in herdr to open Plannotator. This applies to anything that opens plannotator from within a herdr pane.
        terminalBrowser.enable = false;
      };
      
      # The primary distrobox config file
      distrobox.hooks = {
        enable = true;
        docker_sock = true;
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

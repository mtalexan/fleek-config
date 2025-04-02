{ pkgs, misc, lib, config, ... }: {

  imports = [
    ../identities/ks.nix # set the default git identity
    ../programs/ks-dev-tools.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
  ];

  # Make this recursive so we can use ${config.home.username} in the home.homeDirectory, and ${config.home.homeDirectory} 
  # for construcing absolute paths to files.
  config = rec {
    # Host Specific username and home location
    home.username = "dev";
    home.homeDirectory = "/home/${config.home.username}";
    # TODO: Set this to point to the work SSH key 
    #programs.git.signing.key = "${config.home.homeDirectory}/.ssh/github_personal_ed25519";

    #####################################
    # Extra host-unique non-configurable packages
    #####################################
    #home.packages = [];

    #####################################
    # Custom defined config settings
    #####################################
    custom = {
      nixGL.gpu = false;

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

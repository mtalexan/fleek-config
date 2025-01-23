{ pkgs, misc, lib, config, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 
  imports = [
    ../programs/ks-dev-tools.nix
    ../programs/terminator.nix
    ../programs/kitty.nix
    ../programs/distrobox.nix
    ../programs/vscode.nix
  ];

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # Host-specific username and home location
    home.username = "mtalexander";
    home.homeDirectory = "/home/mtalexander";

    # Host-specific default git settings.  Expanded on in the modules/git.nix and programs/git.nix
    programs.git = {
      # optional override uniquely for the host
      #userName = "Mike";
      #userEmail = "github@trackit.fe80.email";

      # SSH default signing key location
      signing = {
          key = "~/.ssh/github_personal_ed25519";
          signByDefault = builtins.stringLength "~/.ssh/github_personal_ed25519" > 0;
      };
    };

    # extra packages that should be installed only on this host
    home.packages = [
      pkgs.rename
      # don't use podman or skopeo from nix,
      # podman is suddenly experiencing a bug where 'podman run --userns:keep-id ...' isn't properly linking
      #   the overlay folders together and fails to start any containers.
      # skopeo wasn't built with glibc-static and CGO, so it can't parse users or groups from LDAP.
    ];

    #####################################
    # Files (arbitrary)
    #####################################

    custom.nixGL.gpu = true;

    # The primary distrobox config file, defined in modules/files.nix
    custom.distrobox = {
      hooks = {
        enable = true;
        host_certs = true;
        docker_sock = true;
      };
      config.engine = "docker";
    };

    #####################################
    # Programs
    #####################################
  };
}

# vim: sw=2:expandtab

{ pkgs, misc, ... }: {
  # extra programs/*.nix to include for this host
  #imports = [];

  config = {
    # Host Specific username and home location
    home.username = "mike";
    home.homeDirectory = "/home/mike";

    # Host-specific default git settings.  Expanded on in the modules/git.nix and programs/git.nix
    programs.git = {
      # optional override uniquely for the host
      #userName = "Mike";
      #userEmail = "github@trackit.fe80.email";

      # SSH default signing key location
      signing = {
          key = "~/.ssh/id_ed25519_github";
          signByDefault = builtins.stringLength "~/.ssh/id_ed25519_github" > 0;
      };
    };

    # extra packages that should be installed only on this host
    #home.packages = [];

    #####################################
    # Files (arbitrary)
    #####################################

    custom.nixGL.gpu = false;

    #####################################
    # Programs
    #####################################
  };
}

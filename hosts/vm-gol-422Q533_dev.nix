{ pkgs, misc, ... }: {
  # extra programs/*.nix to include for this host
  #imports = [];

  config = {
    # Host Specific username and home location
    home.username = "dev";
    home.homeDirectory = "/home/dev";

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

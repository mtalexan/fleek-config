{ pkgs, misc, lib, ... }: {
  # a quick script calling tool from a sub-directory of scripts
  # https://github.com/ianthehenry/sd
  programs.script-directory = {
    enable = true;
    settings = {
      # within the home-manager config folder, ~/.local/share/fleek/sd_scripts.
      # This makes the folder and all files in it part of the nix package automatically, and 
      # uses a path relative to the home-manager root file (flake.nix)
      SD_ROOT = "${../sd_scripts}";
      # defaults to EDITOR or VISUALEDITOR if not set
      SD_EDITOR = "nvim";
      # defaults to 'cat' if not set
      SD_CAT = "bat";
    };
  };
}

# vim: sw=2:expandtab

{ pkgs, misc, lib, config, ... }: {
  # a quick script calling tool from a sub-directory of scripts
  # https://github.com/ianthehenry/sd

  # WARNING: Make sure you open a new terminal window (or a new login session if you don't have it re-sourcing the hmSessionVariables.sh on each load)
  #          in order to see changes to the scripts!

  programs.script-directory = {
    enable = true;
    settings = {
      SD_ROOT = "${../sd_scripts}";
      # defaults to EDITOR or VISUALEDITOR if not set
      SD_EDITOR = "nvim";
      # defaults to 'cat' if not set
      SD_CAT = "bat";
    };
  };
}

# vim: ts=2:sw=2:expandtab

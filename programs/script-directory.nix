{ pkgs, misc, lib, config, ... }: {
  # a quick script calling tool from a sub-directory of scripts
  # https://github.com/ianthehenry/sd

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

# vim: sw=2:expandtab

{ pkgs, misc, lib, ... }: {
  # a quick script calling tool from a sub-directory of scripts
  # https://github.com/ianthehenry/sd

  # programs.script-directory.settings.SD_ROOT doesn't proper track the folder contents to know when to regenerate
  # the nix derivation, so we have to manually put the folders somewhere so that changes will be detected.
  home.file.".local/share/sd" = {
    enable = true;
    recursive = false;
    source = ../sd_scripts;
  };

  programs.script-directory = {
    enable = true;
    settings = {
      # this can't be files in fleek directly or the files will get copied into a derivation that doesn't
      # properly detect when it needs to be updated.  Instead we link the files in our fleeks folder to a location in the HOME,
      # then use that folder as the SD_ROOT
      SD_ROOT = "${config.home.homeDirectory}/.local/share/sd";
      # defaults to EDITOR or VISUALEDITOR if not set
      SD_EDITOR = "nvim";
      # defaults to 'cat' if not set
      SD_CAT = "bat";
    };
  };
}

# vim: sw=2:expandtab

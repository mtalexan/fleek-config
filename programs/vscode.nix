{ pkgs, misc, lib, ... }: {
  # already includes it's own *.desktop entry file, you just have to restart the gnome session to get it to show up

  # Do NOT use the home-manager settings. It installs its own config that prevents the settings from being synced or modified in the GUI.
  # Instead, install only the package.  This still has the program and the desktop files, but doesn't try to manage the settings files.
  home.packages = [
    pkgs.vscode
  ];

  #programs.vscode = {
  #  enable = true;
  #  enableExtensionUpdateCheck = true;
  #  # it always says it's out of date, disable it
  #  enableUpdateCheck = false;
  #  # could be vscodium, or something else. There are a few options
  #  package = pkgs.vscode;
  #
  #  #extensions = [];
  #  #globalSnippets = {};
  #  #keybindings = [];
  #  #languageSnippets = {};
  #
  #  # allow extensions to be installed and managed separately
  #  mutableExtensionsDir = true;
  #
  #  #userSettings = {};
  #  #userTasks = {};
  #};
}

# vim: sw=2:expandtab

{ pkgs, misc, lib, ... }: {
  # already includes it's own *.desktop entry file, you just have to restart the gnome session to get it to show up

  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = true;
    # it always says it's out of date, disable it
    enableUpdateCheck = false;
    # could be vscodium, or something else. There are a few options
    package = pkgs.vscode;

    #extensions = [];
    #globalSnippets = {};
    #keybindings = [];
    #languageSnippets = {};

    # allow extensions to be installed and managed separately
    mutableExtensionsDir = true;

    #userSettings = {};
    #userTasks = {};
  };
}

# vim: sw=2:expandtab

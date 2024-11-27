{ pkgs, misc, lib, ... }: {
  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = true;
    enableUpdateCheck = true;
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

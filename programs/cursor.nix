{ pkgs, misc, lib, config, ... }:
let
  # Stop hook for notifying on Linux when attention is needed.
  cursorAgentNotifier = pkgs.fetchFromGitHub {
    owner = "glira";
    repo = "cursor-agent-notifier";
    rev = "ec1cbad85ea698ea4f2dc5c96e8029831658d915";
    hash = "sha256-mUmDmf1OTc0AnGafK7OpYHPwo7x1j6Q1GTJTjy5U7P4=";
  };
in {
  ## Stop hook for notifying on Linux when attention is needed.

  # File is a nix-store symlink; ~/.cursor and ~/.cursor/hooks are created as user-owned dirs.
  home.file.".cursor/hooks/notify-on-stop.sh" = {
    source = "${cursorAgentNotifier}/hooks/notify-on-stop.sh";
    executable = true;
  };

  # User-level hooks run with cwd ~/.cursor/. mkOrder 1500 so this runs after default-priority stop hooks.
  custom.cursor.hooks.stop = lib.mkOrder 1500 [{
    command = "./hooks/notify-on-stop.sh";
    timeout = 10;
  }];

  #----------------------------------------------------------------------------------------------------

  # already includes it's own *.desktop entry file, you just have to restart the gnome session to get it to show up

  # Do NOT use the home-manager settings. It installs its own config that prevents the settings from being synced or modified in the GUI.
  # Instead, install only the package.  This still has the program and the desktop files, but doesn't try to manage the settings files.
  home.packages = [
    # use the one from a separate flake so we can update it separately. Which package it actually ends up being is set in the flake.nix
    pkgs.code-cursor-independent
    # needed by cursorAgentNotifier
    pkgs.libnotify
  ];

  custom.chezmoi.templates.cursor = {
    enable = true;
    data = {
      # Nix JSON conversion; omit empty hook types. Avoids TOML round-trip of nested lists.
      hooks = builtins.toJSON (
        lib.filterAttrs (_: v: v != []) config.custom.cursor.hooks
      );
    };
  };

  #programs.cursor = {
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

# vim: ts=2:sw=2:expandtab

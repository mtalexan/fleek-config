{ pkgs, misc, lib, config, options, ... }: {
  # Settings shared by all hosts.
  # WARNING: Import depth matters if options are used in files, so this file is included directly
  #          into the flake.nix to reduce the import depth. That *should* let you use options from
  #          files imported here in your host-specific files.

  # globally included packages that have no home-manager config
  home.packages = [
    # user selected packages
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.symbols-only
    pkgs.manix
    pkgs.jq
    pkgs.less
    pkgs.man
    pkgs.noti
    pkgs.yq
    pkgs.riffdiff
  ];

  # "includes". By convention programs/ are for individual programs, while modules/ are less specific.
  # WARNING: If any of these have options defined the import 
  imports = [
    ./nixgl.nix
    ../programs/bash.nix
    ../programs/zsh.nix

    ../programs/atuin.nix
    ../programs/bat.nix
    # set some env variables so the system certificates are used for various tools that don't use them by default
    ../programs/custom-certs.nix
    ../programs/dircolors.nix
    ../programs/eza.nix
    ../programs/fd.nix
    ../programs/fzf.nix
    ../programs/git.nix
    # just adds to the path if already installed
    ../programs/golang.nix
    # adds the homebrew path and completions if already installed
    ../programs/homebrew.nix
    ../programs/jq.nix
    ../programs/less.nix
    # this is a GUI app, so individual hosts must add it manually
    #./programs/kitty.nix
    ../programs/man.nix
    ../programs/neovim.nix
    ../programs/nix-index.nix
    ../programs/noti.nix
    ../programs/ripgrep.nix
    # just adds to the path/environment if cargo is already installed
    ../programs/rustup.nix
    ../programs/script-directory.nix
    ../programs/tealdear.nix
    ../programs/tmux.nix

    ../programs/starship.nix
  ];

  # shell aliases used by all shells
  home.shellAliases = {
    "bathelp" = "bat --plain --language=help";
    "batpretty" = "prettybat";
    "cat" = "bat";
    "catp" = "bat -P";
    # runs a custom shell script named fleek-apply
    "fleek-impure" = "fleek-apply --impure";
    # Also see fleek-update, which is a directly callable script
    "fleeks" = "cd ~/.local/share/fleek";
    "gbc" = "git branch --show-current";
    "gbvv" = "git branch -vv";
    "gcm" = "git commit";
    "gd" = "git diff";
    "gdc" = "git diff --cached";
    "glg" = "git log --oneline --decorate --graph";
    "gs" = "git status";
    "la" = "eza -a";
    "ll" = "eza -l";
    "lla" = "eza -l -a";
    "llag" = "eza -l -a --git";
    "llg" = "eza -l --git";
    "ls" = "eza";
    "lt" = "eza --tree";
    "rgfzf" = "sd rg-fzf";
    "tree" = "eza --tree";
  };

  # add to PATH for all shells
  home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/fleek/bin"
  ];

  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
    GCC_COLORS = "error=01;31;warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS";
  };
}

# vim: ts=2:sw=2:expandtab

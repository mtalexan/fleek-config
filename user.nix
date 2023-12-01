{ pkgs, misc, lib, config, options, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek.

  # split up into separate files in the modules folder
  imports = [
    ./modules/files.nix

    ./programs/atuin.nix
    ./programs/bat.nix
    ./programs/dircolors.nix
    ./programs/eza.nix
    ./programs/fzf.nix
    ./programs/git.nix
    ./programs/jq.nix
    ./programs/less.nix
    ./programs/man.nix
    ./programs/neovim.nix
    ./programs/nix-index.nix
    ./programs/noti.nix
    ./programs/ripgrep.nix
    ./programs/script-directory.nix
    ./programs/tealdear.nix
    # this is a GUI app, so individual hosts must add it manually
    #./programs/terminator.nix
    ./programs/tmux.nix
    ./programs/zoxide.nix

    ./modules/prompt.nix
    ./modules/shells.nix
  ];
}

# vim: sw=2:expandtab
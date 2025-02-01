{ pkgs, misc, lib, config, options, ... }: {
  # Include all modules/*.nix files here somewhere, and include the programs/*.nix files for programs
  # that should be included by all hosts.
  # Host-specific settings should go in hosts/$hostname.nix

  # split up into separate files in the modules folder
  imports = [
    ./modules/nixgl.nix

    ./programs/atuin.nix
    ./programs/bat.nix
    # set some env variables so the system certificates are used for various tools that don't use them by default
    ./programs/custom-certs.nix
    ./programs/dircolors.nix
    ./programs/eza.nix
    ./programs/fd.nix
    ./programs/fzf.nix
    ./programs/git.nix
    # just adds to the path if already installed
    ./programs/golang.nix
    ./programs/home-manager.nix
    # adds the homebrew path and completions if already installed
    ./programs/homebrew.nix
    ./programs/jq.nix
    ./programs/less.nix
    # this is a GUI app, so individual hosts must add it manually
    #./programs/kitty.nix
    ./programs/man.nix
    ./programs/neovim.nix
    ./programs/nix-index.nix
    ./programs/noti.nix
    ./programs/ripgrep.nix
    # just adds to the path/environment if cargo is already installed
    ./programs/rustup.nix
    ./programs/script-directory.nix
    ./programs/tealdear.nix
    ./programs/tmux.nix
    # doesn't do anything useful
    #./programs/z-lua.nix
    #./programs/zoxide.nix

    ./programs/starship.nix
    ./modules/shells.nix
  ];
}

# vim: ts=2:sw=2:expandtab

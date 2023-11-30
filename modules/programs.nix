{ pkgs, misc, lib, ... }: {
  imports = [
    ../programs/atuin.nix
    ../programs/bat.nix
    ../programs/dircolors.nix
    ../programs/eza.nix
    ../programs/fzf.nix
    ../programs/git.nix
    ../programs/jq.nix
    ../programs/less.nix
    ../programs/man.nix
    ../programs/neovim.nix
    ../programs/nix-index.nix
    ../programs/noti.nix
    ../programs/ripgrep.nix
    ../programs/script-directory.nix
    ../programs/tealdear.nix
    ../programs/terminator.nix
    ../programs/tmux.nix
    ../programs/zoxide.nix
  ];
}

# vim: sw=2:expandtab
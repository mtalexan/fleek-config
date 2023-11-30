{ pkgs, misc, lib, ... }: {
  programs.tmux = {
    enable = true;
    historyLimit = 10000000;
    keyMode = "emacs";
    mouse = true;

  };
}

# vim: sw=2:expandtab

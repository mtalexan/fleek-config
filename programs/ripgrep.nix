{ pkgs, misc, lib, ... }: {
  programs.ripgrep = {
    enable = true;
    arguments = [
      # Search hidden files / directories (e.g. dotfiles) by default
      "--hidden"
      # Don't include .git folders.  Requires explicit --glob override on the CLI if we do want to search it
      "--glob=!.git/*"
    ];
  };
}

# vim: ts=2:sw=2:expandtab

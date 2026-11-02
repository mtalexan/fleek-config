{ pkgs, misc, lib, ... }: {

  programs.obsidian = {
    enable = true;
    cli.enable = true;

    # Config isn't mutable if setup here
  };
}

# vim: ts=2:sw=2:expandtab

{ pkgs, misc, lib, config, options, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek.

  # split up into separate files in the modules folder
  imports = [
    ./modules/files.nix
    ./modules/programs.nix
    ./modules/prompt.nix
    ./modules/shells.nix
  ];
}

# vim: sw=2:expandtab
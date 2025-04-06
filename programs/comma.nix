{ pkgs, misc, lib, ... }: {

  #home.packages = [
  #  pkgs.comma.out
  #];

  # inexplicably the only option actually provided by the nix-index-database home manager module under
  # it's own name.
  programs.nix-index-database = {
    # enables substitution of the comma tool with one that uses the nix-index-database to find which
    # package to install.
    comma.enable = true;
  };
}

# vim: ts=2:sw=2:expandtab

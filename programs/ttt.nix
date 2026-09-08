{ pkgs, misc, lib, config, inputs, ... }: {
  config = {
    home.packages = [
      pkgs.ttt

      # needs language-servers.nix as well
      
      # spell checking
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.aspellDicts.en-computers
      pkgs.aspellDicts.en-science
    ];
  };
}

# vim: ts=2:sw=2:expandtab

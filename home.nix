{ config, pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      
      
    };
  };

  
  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
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
    # Fleek Bling
    pkgs.git
# This no longer works, nerdfonts has been split up and this is installed as pkgs.nerd-fonts.fira-code
#    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  fonts.fontconfig.enable = true; 
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;
}

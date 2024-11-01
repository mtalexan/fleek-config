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

  
  # managed by fleek, modify ~/.fleek.yml to change installed packages
  
  # packages are just installed (no configuration applied)
  # programs are installed and configuration applied to dotfiles
  home.packages = [
    # user selected packages
    pkgs.nerdfonts
    pkgs.git
    pkgs.fd
    pkgs.manix
    pkgs.jq
    pkgs.less
    pkgs.man
    pkgs.nix-index
    pkgs.nixgl.nixGLIntel
    pkgs.noti
    pkgs.bashInteractive
    pkgs.zsh-completions
    pkgs.zsh-fzf-tab
    pkgs.nix-zsh-completions
    pkgs.zsh-autosuggestions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.bash-completion
    pkgs.nix-bash-completions
    pkgs.yq
    pkgs.riffdiff
    # Fleek Bling
    pkgs.git
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  fonts.fontconfig.enable = true; 
  home.stateVersion =
    "22.11"; # To figure this out (in-case it changes) you can comment out the line and see what version it expected.
  programs.home-manager.enable = true;
}

{ pkgs, misc, lib, config, options, ... }: {
  # This file includes only definitions that are mandatory for things to function.

  imports = [
    ./modules/all.nix
  ];

  # These are mandatory

  home.sessionPath = [
      "$HOME/.nix-profile/bin"
      "$HOME/bin"
  ];

  # Need to set the zsh and bash settings to ensure 
  programs.zsh ={
    profileExtra = ''
      [ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh
      export XCURSOR_PATH=$XCURSOR_PATH:/usr/share/icons:~/.local/share/icons:~/.icons:~/.nix-profile/share/icons
    '';
    enableCompletion = true;
  };

  programs.bash = {
    profileExtra = ''
      [ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh
      export XCURSOR_PATH=$XCURSOR_PATH:/usr/share/icons:~/.local/share/icons:~/.icons:~/.nix-profile/share/icons
    '';
    enableCompletion = true;
    enable = true;
  };
}

# vim: ts=2:sw=2:expandtab

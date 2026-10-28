{ pkgs, misc, lib, config, options, ... }:
let
  sessionPaths = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "$HOME/bin"
  ];
in
{
  # This file includes only definitions that are mandatory for things to function.

  imports = [
    ./modules/all.nix
  ];

  # These are mandatory

  home.sessionPath = sessionPaths;

  # Ubuntu's GDM starts Wayland sessions without a login shell, so shell
  # PATH setup does not reach systemd user units. Instead, the Wayland session
  # is started as a systemd user unit. Home manager populates the extra environment
  # for that separately.
  systemd.user.sessionVariables.PATH =
    "${lib.concatStringsSep ":" sessionPaths}:$PATH";

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

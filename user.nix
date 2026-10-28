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
  # PATH setup does not reach systemd user units. Set PATH through environment.d
  # for them. This is the correct method on most systems. It is written to
  # 10-home-manager.conf.
  systemd.user.sessionVariables.PATH =
    "${lib.concatStringsSep ":" sessionPaths}:$PATH";

  # Ubuntu's 99-environment.conf (a symlink to /etc/environment) forcibly
  # overwrites PATH, discarding the value from every environment.d file that
  # sorts before it, including 10-home-manager.conf. Add a file that sorts
  # after it (and after 990-snapd.conf) to restore what it wiped out.
  xdg.configFile."environment.d/995-nix-path.conf".text = ''
    PATH=${lib.concatStringsSep ":" sessionPaths}:$PATH
  '';

  # KDE's kded6 rebuilds its application cache (ksycoca) only when a watched
  # applications/ directory changes. Nix profile switches only swap symlinks, so
  # the cache can keep stale entries. It also keeps entries dropped for a
  # failed TryExec, which is evaluated only at build time.
  # Home Manager runs activation with a restricted PATH, so add the system
  # directories where Ubuntu installs kbuildsycoca6.
  home.activation.rebuildKdeSycoca = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    PATH="$PATH:/usr/local/bin:/usr/bin"
    if command -v kbuildsycoca6 >/dev/null 2>&1; then
      kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
    fi
  '';

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

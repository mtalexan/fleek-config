{ pkgs, misc, ... }: {
  # Default fleek settings. File must exist for certain Nix use-cases.
  programs.zsh.profileExtra = ''
    [ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh
    export XCURSOR_PATH=$XCURSOR_PATH:/usr/share/icons:~/.local/share/icons:~/.icons:~/.nix-profile/share/icons
  '';
  programs.zsh.enableCompletion = true;
  programs.zsh.enable = true;
}
# vim: ts=2:sw=2:expandtab

{ pkgs, misc, ... }: {
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/fleek/bin"
 ];
}

# vim: ts=2:sw=2:expandtab

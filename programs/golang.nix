{ pkgs, misc, lib, ... }: {
  # Doesn't actually install golang

    home.sessionPath = [
      "/usr/local/go/bin"
    ];
}

# vim: ts=2:sw=2:expandtab

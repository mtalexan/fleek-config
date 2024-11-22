{ pkgs, misc, lib, ... }: {
  # Doesn't actually install golang

    home.sessionPath = [
      "/usr/local/go/bin"
    ];
}

# vim: sw=2:expandtab

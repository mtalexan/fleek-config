{ pkgs, misc, lib, ... }: {
  # Doesn't actually install golang

    home.sessionPath = [
      "/usr/local/go"
    ];
}

# vim: sw=2:expandtab

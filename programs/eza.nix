{ pkgs, misc, lib, ... }: {
  programs.eza = {
    enable = true;
    # set explicitly instead for clarity
    #enableAliases = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}

# vim: ts=2:sw=2:expandtab

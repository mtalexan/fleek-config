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

# vim: sw=2:expandtab

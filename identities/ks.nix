{ pkgs, misc, lib, config, options, ... }: {
  # KS identity
  # Set the programs.git.signing.key on each system

  programs.git = {
    userName = "Alexander, Michael";
    userEmail = "michael.alexander@karlstorz.com";

    extraConfig = {
      url = {
        # force SSH cloning from GitHub repos, never HTTPS
        "ssh://git@github.com" = {
              insteadOf = "https://github.com";
        };
        # force SSH cloning from GitHub repos, never HTTPS
        "ssh://git@scm-02.karlstorz.com" = {
              insteadOf = "https://scm-02.karlstorz.com";
        };
        "ssh://git@scm-01.karlstorz.com" = {
              insteadOf = "https://scm-01.karlstorz.com";
        };
      };
    };

    signing = {
        # Presumes the SSH key path is set per-host

        # If we made this structure rec, we should theoretically be able to set this conditionally based
        # on whether the specific host has actually set the key.
        # signByDefault = builtins.stringLength key > 0;
        # Assume a key will eventually be set, even if not thru nix
        signByDefault = true;
    };
  };
}

# vim: ts=2:sw=2:expandtab

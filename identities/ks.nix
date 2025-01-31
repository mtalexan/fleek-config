{ pkgs, misc, lib, config, options, ... }: {
  # KS identity
  # Set the programs.git.signing.key on each system

  programs.git = {
    # Intentionally not setting private details (yet)!

    signing = {
        # Presumes the SSH key path is set per-host

        # If we made this structure rec, we should theoretically be able to set this conditionally based
        # on whether the specific host has actually set the key.
        # signByDefault = builtins.stringLength key > 0;
        # Assume a key will eventually be set, even if not thru nix
        
        # not yet
        #signByDefault = true;
    };
  };
}

# vim: ts=2:sw=2:expandtab

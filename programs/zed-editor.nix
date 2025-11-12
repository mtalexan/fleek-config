{ pkgs, misc, lib, config, ... }: {
  # zed editor, but without the actual package.
  # Zed suffers from similar issues to VSCode, in that the language servers and extra data
  # it downloads for extensions don't work properly when Zed is a nix package.
  
  # The Zed flake overlay has pkgs.zed-editor in it, but that's updated nightly and tends to be pretty unstable.
  # It used to be that that was the only way to get an FHS that would allow installing extensions from an external source,
  # but now the nixpkgs:unstable has zed-editor-fhs that's based on the weekly stable releases.
  
  config = {

    # If we're managing the config externally via the git repo folder, install the
    # packages zed needs to have externally installed.
    # Otherwise, these are part of the programs.zed-editor.extraPackages.
    home.packages = [
        # Nix language server has to be manually installed external to zed. Install both even though only one usually gets used.
        pkgs.nixd
        pkgs.nil
        # needed by Basher extension
        pkgs.shellcheck
        pkgs.zed-editor-fhs
      ];
    home.file =
    #{
    #  # Setup the ~/.zed_server folder. This is used as the location for incoming clients to put their
    #  # version of the zed server when doing remote connections, as well as the source of the binary
    #  # for when making remote connections that have '"upload_binary_over_ssh": true' set.
    #  # Zed uses SSH for actual connection and authentication, so this configuration has no effect on
    #  # whether or not remote access is really allowed to this system.
    #  ".zed_server" = {
    #    # Set it up as a folder in the real location with everything relevant symlinked in.
    #    # This allows clients to add their own server versions to this folder if the one already
    #    # here doesn't match (client and server versions need to match exactly).
    #    recursive = true;
    #    source = "${pkgs.zed-editor-fhs.remote_server}/bin";
    #  };
    #} //
    {
      # Create a symlink ~/.config/zed that redirects (thru a few different symlinks) to the real on-disk path of the 
      # zed-editor folder next to this file.
      # The config.lib.file.mkoutOfStoreSymlink will do this for whatever file you pass it.
      # However, nix paths (like ./zed-editor) can only refer to files within the flake after it's been captured into the nix-store.
      # And since all flake evaluation only happens after the files have been copied into that nix-store, there is no way for nix to
      # construct the path to the code the flake in the store was copied from. It just has to be hardcoded as a path to where the flake code is stored.
      ".config/zed".source =  config.lib.file.mkOutOfStoreSymlink "${config.custom.configdir}/programs/zed-editor";
    };
  };
}

# vim: ts=2:sw=2:expandtab

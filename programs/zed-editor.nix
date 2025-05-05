{ pkgs, misc, lib, config, ... }: {
  # Much like vscode, zed doesn't have a separate default settings vs overrides
  # for it's config, so we can't have different config settings per host unless
  # we set it here. And that also prevents us from manually overriding some settings
  # temporarily.

  # Don't use the nix version of Zed, it doesn't work properly.
  # Install it manually from https://zed.dev/download
  ## install the package, but don't use the home-manager setting yet
  ##home.packages = [
  ##  pkgs.zed-editor
  ##];

  # Create a symlink ~/.config/zed that redirects (thru a few different symlinks) to the real on-disk path of the 
  # zed-editor folder next to this file.
  # The config.lib.file.mkoutOfStoreSymlink will do this for whatever file you pass it.
  # However, nix paths (like ./zed-editor) can only refer to files within the flake after it's been captured into the nix-store.
  # And since all flake evaluation only happens after the files have been copied into that nix-store, there is no way for nix to
  # construct the path to the code the flake in the store was copied from. It just has to be hardcoded as a path to where the flake code is stored.
  home.file.".config/zed".source =  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/share/fleek/programs/zed-editor";

  #programs.zed-editor = {
  #  enable = true;
  # 
  #};
}

# vim: ts=2:sw=2:expandtab

{ pkgs, misc, lib, config, ... }: {
  # Much like vscode, zed doesn't have a separate default settings vs overrides
  # for it's config, so we can't have different config settings per host unless
  # we set it here. And that also prevents us from manually overriding some settings
  # temporarily.

  # Don't use the nix version of Zed, it doesn't work properly.
  # Install it manually from https://zed.dev/download instead.
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

  # Zed uses a certain Vulkan rendering crate that only works on systems with
  # specific Vulkan APIs and Wayland compositor. For some systems this is satisfied,
  # but many (e.g. Ubuntu with KDE that's still stuck, on X11) it's not possible to provide this.
  # A warning will be shown on every startup where this isn't satisfied if you don'to
  # set an environment variable to acknowledge it.
  # home.sessionVariables = {
  #   # This forces fallback to X11 when both Wayland and X11 are present, but still requires the host Vulkan
  #   # tools to support X11 as well (Ubuntu 24.04 doesn't).
  #   WAYLAND_DISPLAY = "";
  #   # disable the zed warning about falling back to SW rendering.
  #   ZED_ALLOW_EMULATED_GPU = "1";
  # };
  
  # WARNING: Requires manually updating the zed settings with the list of installed extensions to get them to sync
  
  #programs.zed-editor = {
  #  enable = true;
  # 
  #};
}

# vim: ts=2:sw=2:expandtab

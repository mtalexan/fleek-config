{ pkgs, misc, lib, ... }: {
  # a Rust-based terminal emulator that's fast, simple, and has modern support
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}

# vim: sw=2:expandtab

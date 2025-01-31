{ pkgs, misc, lib, ... }: {
  # a Rust-based tldr program
  programs.tealdeer = {
    enable = true;
    # see https://dbrgn.github.io/tealdeer/config.html
    settings = {
      display = {
        use_pager = true;
        compact = false;
      };
      # style = {};
      updates = {
        auto_update = true;
        # auto_update_interval = 720; # default
      };
      # directories = {};
    };
  };
}

# vim: ts=2:sw=2:expandtab

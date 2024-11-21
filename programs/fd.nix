{ pkgs, misc, lib, ... }: {
  programs.fd = {
    enable = true;

    extraOptions = [
      # don't respect .gitignore by default. Use --ignore-vcs to override.
      "--no-ignore-vcs"
      # respect .gitignore and global git file ignore settings even if it's not in a git repo. Use --require-git to override.
      #"--no-require-git"
      # list relative paths. Use -a or --absolute-path to override
      "--relative-path"
      # Show file system errors for deadlinks and/or insufficient permissions
      "--show-errors"
    ];

    # search hidden folders too
    hidden = true;

    # list of paths to ignore
    ignores = [
      ".git/"
      "*.bak"
    ];
  }
}

# vim: sw=2:expandtab

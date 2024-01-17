{ pkgs, misc, lib, ... }: {
  # Adds homebrew tools to the path, and adds shell completion for them.
  # Recommended:
  #   - Install the equivalent of 'build-essential'
  #   - 'brew install gcc'
  #
  # WARNING: homebrew should be installed before this is included in the custom.nix file

  zsh.initExtra = lib.concatLines [
    ''
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ''
  ]

  bash.initExtra = lib.concatLines [
    ''
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ''
  ]
}

# vim: sw=2:expandtab

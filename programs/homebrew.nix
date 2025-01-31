{ pkgs, misc, lib, ... }: {
  # Adds homebrew tools to the path, and adds shell completion for them.
  # Recommended:
  #   - Install the equivalent of 'build-essential'
  #   - 'brew install gcc'
  #
  # WARNING: homebrew should be installed before this is included in the custom.nix file
  #          https://brew.sh/

  programs.zsh = {
    initExtraBeforeCompInit = lib.concatLines [
      ''
      # put 'brew' in the path
      if [ -e /home/linuxbrew/.linuxbrew/bin/brew ] ; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        # add completions from brew-installed tools
        if command -v brew &>/dev/null; then
          FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
        fi
      fi
      ''
    ];
  };

  programs.bash.initExtra = lib.concatLines [
    ''
    # put 'brew' in the path
    if [ -e /home/linuxbrew/.linuxbrew/bin/brew ] ; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

      homebrew_prefix="$(brew --prefix)"

      # add completions

      # use /etc/profile.d/bash_completions.sh if it exists, otherwise 
      # use each file from /etc/bash_completions.d/*
      if [[ -r "$homebrew_prefix/etc/profile.d/bash_completions.sh" ]]; then
        source "$homebrew_prefix/etc/profile.d/bash_completions.sh"
      else
        for C in "$homebrew_prefix/etc/bash_completions.d/"* ; do
          [[ -r "$C" ]] && source "$C"
        done
      fi
    fi
    ''
  ];
}

# vim: ts=2:sw=2:expandtab

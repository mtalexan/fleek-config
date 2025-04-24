{ pkgs, misc, lib, config, ... }: {
  # Normally the instructions are to source the ${HOME}/DevTools/.bashrc file, but
  # all that does is add the ${HOME}/DevTools/bin folder to the PATH, and
  # source all the bash-completion files in ${HOME}/DevTools/bash-completion.d.

  # add the extra DevTools path, just in case it's there.  If it is, it's relevant
  home.sessionPath = [
    "$HOME/DevTools/bin"
  ];

  programs.bash.initExtra = ''
    if [[ -d $HOME/DevTools/bash-completion.d ]]; then
      for f in "$HOME/DevTools/bash-completion.d/"* ; do
        source "$f"
      done
    fi
  '';

  # We have bash-completion compatiblity enabled in zsh, so source the bash-completion files too.
  # default priority, formerly initExtra
  programs.zsh.initContent = lib.mkMerge [ (lib.mkOrder 1000 ''
    if [[ -d $HOME/DevTools/bash-completion.d ]]; then
      for f in "$HOME/DevTools/bash-completion.d/"* ; do
        source "$f"
      done
    fi
  '')];
}

# vim: ts=2:sw=2:expandtab

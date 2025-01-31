{ pkgs, misc, lib, config, ... }: {
  config = {
    # add the extra DevTools path, just in case it's there.  If it is, it's relevant
    home.sessionPath = [
      "$HOME/DevTools/bin"
    ];

    programs.bash.initExtra = lib.concatLines [
      ''
      if [ -e "$HOME/DevTools/.bashrc" ] ; then
        source $HOME/DevTools/.bashrc
      fi
      ''
    ];

    #programs.zsh.initExtra = lib.concatLines [
    #];
  };
}

# vim: ts=2:sw=2:expandtab

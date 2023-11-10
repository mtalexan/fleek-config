{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  # configured in the main file, selected to be enabled for this host
  home.file.distrobox_config.enable = true;
  home.file.distrobox_hooks.enable = true;

  home.sessionPath = [
    "$HOME/DevTools/bin"
  ];

  programs.bash.initExtra = ''
    
    if [ -e "$HOME/.cargo/env" ] ; then
      source $HOME/.cargo/env
    fi
    if [ -e "$HOME/DevTools/.bashrc" ] ; then
      source $HOME/DevTools/.bashrc
    fi
    if [ -e "$HOME/.jfrog/jfrog_bash_completion" ] ; then
      source $HOME/.jfrog/jfrog_bash_completion
    fi
  '';
  programs.zsh.initExtra = ''

    if [ -e "$HOME/.cargo/env" ] ; then
      source $HOME/.cargo/env
    fi
    if [ -e "$HOME/.jfrog/jfrog_bash_completion" ] ; then
      source $HOME/.jfrog/jfrog_bash_completion
    fi
  '';
}

# vim: sw=2:expandtab

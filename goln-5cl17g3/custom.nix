{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  #####################################
  # Files (arbitrary)
  #####################################

  home.file = {
    # The primary distrobox config file
    ".config/distrobox/distrobox.conf" = {
      enable = true;
      # add an extra line specifically to on this host
      text = [
        # configure it to use docker
        ''container_manager="docker"''
      ];
    };

    # distrobox hooks to copy are host-name specific
    ".config/distrobox" = {
      enable = true;
      # has to be set here so it's in the hostname-specific folder
      source = ./home_files/distrobox;
    };
  };

  #####################################
  # Programs
  #####################################

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

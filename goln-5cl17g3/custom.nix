{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  #####################################
  # Files (arbitrary)
  #####################################

  # The primary distrobox config file
  home.file.distrobox_config = {
    enable = true;
    executable = false;
    # target, relative to HOME
    target = ".config/distrobox/distrobox.conf";
    text = [
      # support the init hooks (see home.file.distrobox_preinithooks)
      """container_pre_init_hook="~/.config/distrobox/pre-init-hooks.sh""""
      # support the init hooks (see home.file.distrobox_inithooks)
      """container_init_hook="~/.config/distrobox/init-hooks.sh""""
      # configure it to use docker
      """container_manager="docker""""
    ];
  };

  # distrobox hooks to copy are host-name specific
  home.file.distrobox_hooks = {
    enable = true;
    # keep the permissions from the files in the fleek folder
    executable = null;
    # Make each individual file a symlink in the copy rather than symlinking the
    # whole directory. We put home.file.distrobox_config here too, so we can't do the
    # latter.
    recursive = true;

    target = ".config/distrobox"
    # relative to the repo root, under the host-specific folder
    source = "home_files/distrobox";
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

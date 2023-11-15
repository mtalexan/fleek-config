{ pkgs, misc, lib, config, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  # declare it explicitly so we can access the config.custom.files section to set options as well
  config = {
    # extra packages that should be installed only on this host
    home.packages = [
      pkgs.distrobox
      pkgs.podman
      pkgs.skopeo
    ];

    #####################################
    # Files (arbitrary)
    #####################################

    # The primary distrobox config file
    custom.distrobox = {
      hooks = {
        enable = true;
        host_certs = true;
        docker_sock = true;
      };
      config.engine = "docker";
    };
    ## add an extra line specifically to on this host for the distrobox config
    #home.file.".config/distrobox/distrobox.conf".text =
    #    ''
    #      # configure it to use docker
    #      container_manager="docker"
    #    '';

    custom.podman.config = {
      ubuntu = true;
      shortnames = true;
    };

    #####################################
    # Programs
    #####################################

    # add the extra DevTools path, just in case it's there.  If it is, it's relevant
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
  };
}

# vim: sw=2:expandtab

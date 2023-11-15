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
    custom.files.".config/distrobox/distrobox.conf".enable = false;
    # add an extra line specifically to on this host.
    home.file.".config/distrobox/distrobox.conf".text =
        ''
          # configure it to use docker
          container_manager="docker"
        '';

    # distrobox hooks. setup is hostname-specific
    custom.files.".config/distrobox".enable = true;
    # has to be set here so relative path is in the hostname-specific folder
    home.file.".config/distrobox".source = ./home_files/distrobox;

    # basic shared Ubuntu-style podman setup
    custom.files.".config/containers".enable = true;

    # common podman shortname aliases for public imaes
    custom.files.".config/containers/registries.conf.d/000-shortnames.conf".enable = true;

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
  };
}

# vim: sw=2:expandtab

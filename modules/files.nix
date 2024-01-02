{ pkgs, misc, lib, config, options, ... }: {
  # Arbitrary config files go in here.

  # All the files/folders in here are in blocks that specify a common behavior, but are disabled by default.
  # They specify an options.custom.files.X.enable so they can conditionally be enabled in the host-specific
  # custom.nix.

  # Unlike the other files, which define things that are part of 'config' only and therefore don't need to
  # expliictly specify it, this file sets 'options' as well so everything else needs to indicate 'config'.

  #####################################
  # Distrobox
  #####################################

  # Supports some basic distrobox customization.
  # config.
  #   engine : string : can be set to the name of a container engine that will be included explicitly in the distrobox.conf.
  #            without this setting, distrobox picks whichever is  installed, and may prefer an unexpected engine
  #            when multiple are installed.
  #   extra : string : any extra options to add to the distrobox.conf.  Should be a string with \n.
  # hooks.
  #   enable : T/F : Add the pre-init and init hook directories with scripts to parse them, and add the hook scripts
  #            to the distrobox.conf.  Automatically adds an init-hook.d/20-nix.sh that will map thru the nix
  #            store and commands from the host.
  #   host_certs : T/F : Injects extra custom certificates from the host into the containers.  Also adds any certs from
  #                the ~/.config/distrobox/certs/ folder.
  #   docker_sock : T/F : Maps the docker socket from the host into the container with the proper permissions.  Assumes
  #                 the container has client tools installed that are able to make use of the socket.
  options.custom.distrobox = with lib; {
    config = {
      engine = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If set to non-null, the container engine is explicitly set in the distrobox.conf";
      };
      extra = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Any extra options to add to the distrobox.conf";
      };
    };
    hooks = {
      # includes the nix hook by default
      enable = mkEnableOption(mdDoc "distrobox pre-init and init hooks directories, including nix passthru hook");
      host_certs = mkEnableOption(mdDoc "distrobox host certificate injection hook");
      docker_sock = mkEnableOption(mdDoc "distrobox docker socket passthru hook, including permissions");
    };
  };

  config.home.file.".config/distrobox/distrobox.conf" = {
    enable = config.custom.distrobox.hooks.enable || (config.custom.distrobox.config.engine != null) || (config.custom.distrobox.config.extra != null);
    executable = false;
    text = "" +
      lib.optionalString config.custom.distrobox.hooks.enable
        ''
          container_pre_init_hook="~/.config/distrobox/pre-init-hooks.sh"
          container_init_hook="~/.config/distrobox/init-hooks.sh"
        ''
      +
      lib.optionalString (config.custom.distrobox.config.engine != null)
        ''
          container_manager="${config.custom.distrobox.config.engine}"
        ''
      +
      lib.optionalString (config.custom.distrobox.config.extra != null) config.custom.distrobox.config.extra
    ;
  };
  config.home.file.".config/distrobox/init-hooks.sh" = {
    enable = config.custom.distrobox.hooks.enable || config.custom.distrobox.hooks.host_certs || config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/init-hooks.sh;
  };
  config.home.file.".config/distrobox/pre-init-hooks.sh" = {
    enable = config.custom.distrobox.hooks.enable || config.custom.distrobox.hooks.host_certs || config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/pre-init-hooks.sh;
  };
  config.home.file.".config/distrobox/pre-init-hooks.d/.keep" = {
    enable = config.custom.distrobox.hooks.enable || config.custom.distrobox.hooks.host_certs || config.custom.distrobox.hooks.docker_sock;
    executable = false;
    # only used to ensure the folder exists
    text = "";
  };
  config.home.file.".config/distrobox/init-hooks.d/20-nix.sh" = {
    enable = config.custom.distrobox.hooks.enable || config.custom.distrobox.hooks.host_certs || config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/init-hooks.d/20-nix.sh;
  };


  config.home.file.".config/distrobox/certs/.keep" = {
    enable = config.custom.distrobox.hooks.host_certs;
    executable = false;
    # only used to ensure the folder exists
    text = "";
  };
  config.home.file.".config/distrobox/pre-init-hooks.d/00-root-cas.sh" = {
    enable = config.custom.distrobox.hooks.host_certs;
    executable = true;
    source = ../home_files/distrobox/pre-init-hooks.d/00-root-cas.sh;
  };


  config.home.file.".config/distrobox/init-hooks.d/30-docker-sock.sh" = {
    enable = config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/init-hooks.d/30-docker-sock.sh;
  };

  #####################################
  # Podman
  #####################################

  # Supports automated setup of some common podman-on-Ubuntu settings.
  # config.
  #   ubuntu : T/F : Adds a pre-defined storage.conf, default registries via registries.conf, sig-store location
  #            via registries.d/default.yaml, and policy.json for loopback access to the containers.
  #            Likely the pkgs.catatonit will also need to be installed with pkgs.podman so the --init option to podman
  #            works.
  #   shortnames : T/F : Adds a list of short aliases for common public images via registries.conf.d/000-shortnames.conf
  options.custom.podman.config = with lib; {
    # includes the nix hook by default
    ubuntu = mkEnableOption(mdDoc "podman ubuntu-like libpod.conf and default public registries");
    shortnames = mkEnableOption(mdDoc "podman shortname aliases for common public images");
  };


  config.home.file.".config/containers/libpod.conf" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/libpod.conf;
  };
  config.home.file.".config/containers/registries.conf" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/registries.conf;
  };
  config.home.file.".config/containers/policy.json" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/policy.json;
  };

  config.home.file.".config/containers/registries.conf.d/000-shortnames.conf" = {
    enable = config.custom.podman.config.shortnames;
    executable = false;
    source = ../home_files/podman_config/registries.conf.d/000-shortnames.conf;
  };

  #####################################
  # Extraterm
  #####################################

  # Terminal emulator. Uses the new Qt version (post 0.60.0). Includes some custom shell commands and command
  # framing support.
  # Currently setup of 0.75.0.
  #   enable : T/F : Installs the AppImage as 'extraterm' in ~/.local/bin. First time running it on a system adds options to the GUI.
  #   enableBashIntegration : T/F : Adds sourcing of the shell integration scripts needed for framing, 'from', and 'show' commands to bashrc
  #   enableZshIntegration : T/F : Adds sourcing of the shell integration scripts needed for framing, 'from', and 'show' commands to zshrc
  #   enableFishIntegration : T/F : Adds sourcing of the shell integration scripts needed for framing, 'from', and 'show' commands to fishrc
  options.custom.extraterm.config = with lib; {
    enable = mkEnableOption(mdDoc "Enable extraterm AppImage in the ~/.local/bin (PATH) as 'extraterm'");
    enableBashIntegration = mkEnableOption(mdDoc "Enable bash integration required for framing and 'from' and 'show' commands.");
    enableZshIntegration = mkEnableOption(mdDoc "Enable zsh integration required for framing and 'from' and 'show' commands.");
    enableFishIntegration = mkEnableOption(mdDoc "Enable fish integration required for framing and 'from' and 'show' commands.");
  };

  config.home.file.".local/bin/extraterm" = {
    enable = config.custom.extraterm.config.enable;
    executable = true;
    source = ../home_files/extraterm/ExtratermQt-0.75.0.glibc2.34-x86_64.Appimage;
  };

  config.home.file.".config/extraterm/integrations" = {
    enable = config.custom.extraterm.config.enableBashIntegration || config.custom.extraterm.config.enableZshIntegration || config.custom.extraterm.config.enableFishIntegration;
    recursive = false; # symlink the whole folder, not each file in it
    # let execute bit be defined individually by the files in the linked directory
    source = ../home_files/extraterm/extraterm-commands-0.75.0;
  };
  (mkIf config.custom.extraterm.config.enableBashIntegration {
    config.programs.bash.initExtra = lib.concatLines [
      "source $HOME/.config/extraterm/integrations/setup_extraterm_bash.sh"
    ];
  })
  (mkIf config.custom.extraterm.config.enableZshIntegration {
    config.programs.zsh.initExtra = lib.concatLines [
      "source $HOME/.config/extraterm/integrations/setup_extraterm_zsh.zsh"
    ];
  })
  (mkIf config.custom.extraterm.config.enableFishIntegration {
    config.programs.fish.initExtra = lib.concatLines [
      "source $HOME/.config/extraterm/integrations/setup_extraterm_fish.fish"
    ];
  })
}

# vim: sw=2:expandtab
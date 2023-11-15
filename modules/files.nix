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

  # Adds scripts for parsing hooks from directories, the directory structure itself, and the settings in the
  # distrobox.confto use the hooks.  Always includes the hooks for passing thru nix support.
  # Optionally includes the hooks for injecting the host certs, and for passing thru the docker socket (with permissions).
  # Extra distrobox.conf can be specified by putting it in home.file.".config/distrobox/distrobox.conf".text in a custom.nix
  options.custom.distrobox = with lib; {
    config = {
      engine = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If set to non-null, the container engine is explicitly set in the distrobox.conf";
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
    enable = config.custom.distrobox.hooks.enable or (config.custom.distrobox.config.engine != null);
    executable = false;
    text = lib.concatLines [
      #lib.optionalString config.custom.distrobox.hooks.enable ''
        ''
          container_pre_init_hook="~/.config/distrobox/pre-init-hooks.sh"
          container_init_hook="~/.config/distrobox/init-hooks.sh"
        ''
      #lib.optionalString (config.custom.distrobox.hooks.config.engine != null) ''
        ''
          container_manager="${config.custom.distrobox.config.engine}"
        ''
    ];
  };
  config.home.file.".config/distrobox/init-hooks.sh" = {
    enable = config.custom.distrobox.hooks.enable or config.custom.distrobox.hooks.host_certs or config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/init-hooks.sh;
  };
  config.home.file.".config/distrobox/pre-init-hooks.sh" = {
    enable = config.custom.distrobox.hooks.enable or config.custom.distrobox.hooks.host_certs or config.custom.distrobox.hooks.docker_sock;
    executable = true;
    source = ../home_files/distrobox/pre-init-hooks.sh;
  };
  config.home.file.".config/distrobox/pre-init-hooks.d/.keep" = {
    enable = config.custom.distrobox.hooks.enable or config.custom.distrobox.hooks.host_certs or config.custom.distrobox.hooks.docker_sock;
    executable = false;
    # only used to ensure the folder exists
    text = "";
  };
  config.home.file.".config/distrobox/init-hooks.d/20-nix.sh" = {
    enable = config.custom.distrobox.hooks.enable or config.custom.distrobox.hooks.host_certs or config.custom.distrobox.hooks.docker_sock;
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

  # Adds basic config for podman, and optionally a predefined list of shortname aliases for public images.
  # Will run an onChange hook to verify you have newuidmap and newgidmap available, and are in the /etc/subuid
  # and /etc/subgid files.
  options.custom.podman.config = with lib; {
    # includes the nix hook by default
    ubuntu = mkEnableOption(mdDoc "podman ubuntu-like storage.conf, default registries, and sig-store");
    shortnames = mkEnableOption(mdDoc "podman shortname aliases for common public images");
  };


  config.home.file.".config/containers/storage.conf" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/storage.conf;
  };
  config.home.file.".config/containers/registries.conf" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/registries.conf;
  };
  config.home.file.".config/containers/registries.d/default.yaml" = {
    enable = config.custom.podman.config.ubuntu;
    executable = false;
    source = ../home_files/podman_config/registries.d/default.yaml;
  };


  config.home.file.".config/containers/registries.conf.d/000-shortnames.conf" = {
    enable = config.custom.podman.config.shortnames;
    executable = false;
    source = ../home_files/podman_config/registries.conf.d/000-shortnames.conf;
  };
}

# vim: sw=2:expandtab
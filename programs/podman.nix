{ pkgs, misc, lib, config, options, ... }: {
  # Arbitrary config files go in here.

  # Specify an options.custom.files.X.enable so they can conditionally be enabled in the host-specific
  # custom.nix.

  # Unlike the other files, which define things that are part of 'config' only and therefore don't need to
  # explicitly specify it, this file sets 'options' as well so everything else needs to indicate 'config'.

  config.home.packages = [
    pkgs.podman
  ];


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
}

# vim: ts=2:sw=2:expandtab
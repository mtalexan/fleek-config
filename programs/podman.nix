{ pkgs, misc, lib, config, options, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

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
  #            Requires ubuntu to also be enabled.
  options.custom.podman.config = with lib; {
    ubuntu = mkEnableOption(mdDoc "podman ubuntu-like libpod.conf and default public registries");
    shortnames = mkEnableOption(mdDoc "podman shortname aliases for common public images");
  };

  # Podman config files are managed by chezmoi.
  # The source files live in chezmoi/dot_config/containers/ and the .chezmoiignore.tmpl
  # conditionally includes/excludes files based on the data flags below.
  config.custom.chezmoi.templates.podman = {
    enable = config.custom.podman.config.ubuntu;

    data = {
      shortnames = config.custom.podman.config.shortnames;
    };
  };
}

# vim: ts=2:sw=2:expandtab

{ pkgs, misc, lib, config, options, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Not configurable in home-manager itself, add the package generically
  config.home.packages = [
    pkgs.distrobox
  ];

  # Distrobox config files are managed by chezmoi.
  # The source files live in chezmoi/dot_config/distrobox/ and the .chezmoiignore.tmpl
  # conditionally includes/excludes files based on the data flags below.
  config.custom.chezmoi.templates.distrobox = {
    enable = true;

    data = {
      hooks_enable = config.custom.distrobox.hooks.enable;
      host_certs = config.custom.distrobox.hooks.host_certs;
      docker_sock = config.custom.distrobox.hooks.docker_sock;
      engine = if config.custom.distrobox.config.engine != null then config.custom.distrobox.config.engine else "";
      extra = if config.custom.distrobox.config.extra != null then config.custom.distrobox.config.extra else "";
    };
  };

}
# vim: ts=2:sw=2:expandtab

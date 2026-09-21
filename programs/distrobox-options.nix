{ lib, ... }: {
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
}
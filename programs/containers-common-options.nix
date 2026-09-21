{ lib, ... }: {
  options.custom.containers-common.config = with lib; {
    podman = mkEnableOption ''Enable the podman tool from the containers-common set.'';
    skopeo = mkEnableOption ''Enable the skopeo tool from the containers-common set.'';

    dist_config = {
      seccomp = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Creates a seccomp.json in the distribution config that matches the one provided by golang-github-containers-common.
        '';
      };

      cgroup_manager = mkOption {
        type = types.enum [ "cgroup" "systemd" ];
        default = "systemd";
        description = ''
          The cgroup manager to use for podman (cgroup or systemd).
          If the host system uses systemd, this MUST be set to systemd, otherwise it must be set to cgroup.
          This option is always required to be set explicitly.
          '';
      };
    };

    # these are setup via chezmoi so they're still modifiable by the user
    user_config = {
      policy = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Generates an 'insecureAcceptAnything' default policy.json in the distribution config
        '';
      };

      storage_driver = mkOption {
        type = types.nullOr (types.enum [ "overlay" "fuse-overlay" "vfs" ]);
        default = null;
        description = ''
          Create a storage.conf file as part of the distribution config that sets the default storage driver.
          If not set, the file is not created. If the 'overlay' storage driver is selected, the host system must
          have native support for overlayfs in the kernel. If the 'fuse-overlay' is selected, the Nix fuse-overlayfs
          package is used for the driver.
          '';
      };

      containers_conf = {
        tini = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Configures the ~/.config/containers/containers.conf to use tini as the init tool when running with --init, instead
            of the default podman catanonit.
          '';
        };
      };
    };
  };
}
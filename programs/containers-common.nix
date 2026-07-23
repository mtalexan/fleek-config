{ pkgs, misc, lib, config, options, ... }: {
  # Covers both podman and skopeo. Adds distribution config files based on config options.
  # 
  # The only remaining problems with these tools are:
  #   - it includes no config files
  #   - you have to manually install the host-system-installed newuidmap/newgidmap binaries
  #   - you have to explicitly enable CGO_ENABLED=1 for it to build properly and function with PAM (Golang prefers to break PAM by default)
  # Also, the build always sets PREFIX to $out for the package, and in podman's container-common dependencies the distribution-specific config
  # files are in $PREFIX/share/containers/. So we can populate and include the "distro" config files there. The $ETCDIR is set to /etc, overriding the $PREFIX
  # for the system admin config, and keeping it in /etc/containers/.
  # We just need to supply a custom set of config files in $out/share/containers/ that matches for any podman-related tools.

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

  # Assert that cgroup_manager is explicitly set - this is always required
  config = let
    cfgopts = config.custom.containers-common.config;
    cfgoptsdist = cfgopts.dist_config;
    cfgoptsuser = cfgopts.user_config;
    
    # Install seccomp.json from the flake-included dist config
    seccompJson = pkgs.writeTextFile {
      name = "seccomp-dist-conf";
      destination = "/share/containers/seccomp.json";
      text = builtins.readFile ./containers_common_dist_config/seccomp.json;
    };
    
    # Generate containers.conf with cgroup_manager setting
    containersConf = pkgs.writeTextFile {
      name = "containers-dist-conf";
      # Will end up under $out/
      destination = "/share/containers/containers.conf";
      text = ''
        [containers]
        cgroup_manager = "${cfgoptsdist.cgroup_manager}"
      '';
    };
  
    # Wrap a package with the distribution config files via symlinkJoin
    wrapWithDistConfig = pkg: pkgs.symlinkJoin {
      name = "${pkg.pname or pkg.name}-with-dist-config";
      paths = [ pkg ]
        ++ lib.optional cfgoptsdist.seccomp seccompJson
        # this one always needs to be included
        ++ [ containersConf ];
    };
  
  in {
    home.packages = []
      ++ lib.optional cfgopts.podman (wrapWithDistConfig pkgs.podman)
      ++ lib.optional cfgopts.skopeo (wrapWithDistConfig pkgs.skopeo)
      # tini only applies to podman
      ++ lib.optional (cfgopts.podman && cfgoptsuser.containers_conf.tini) pkgs.tini;

    # When defined, we check for needing each file.
    custom.chezmoi.templates.containers_common.data = lib.mkIf (cfgopts.podman || cfgopts.skopeo) {
      # if set, the file 
      storage_driver = if (cfgoptsuser.storage_driver == null) then
                          ""
                        else
                          # fuse-overlay sets the fuse overlay path as well, but has to be listed as type "overlay" in the storage.conf file.
                          if (cfgoptsuser.storage_driver == "fuse-overlay") then
                            "overlay"
                          else
                            cfgoptsuser.storage_driver;
      storage_driver_fuse_path = lib.mkIf (cfgoptsuser.storage_driver == "fuse-overlay") "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";

      # enables the insecureAllowAnything file
      policyjson = cfgoptsuser.policy;

      # Currently the only settings apply only to podman, so only set this if podman is enabled.
      # Only enable the containers_conf if one of the values in it is enabled too.
      # tini specified as in-path above.
      containers_conf = lib.mkIf (cfgopts.podman && cfgoptsuser.containers_conf.tini) {
        enabled = true; 
        init_path = "${pkgs.tini}/bin/tini";
      };
    };
  };
}

# vim: ts=2:sw=2:expandtab

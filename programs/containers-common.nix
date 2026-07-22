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
  };

  # Assert that cgroup_manager is explicitly set - this is always required
  config = let
    cfgopts = config.custom.containers-common.config;
    cfgoptsdist = cfgopts.dist_config;
    
    # Install seccomp.json from the flake-included dist config
    seccompJson = pkgs.writeTextFile {
      name = "seccomp-dist-conf";
      destination = "/share/containers/seccomp.json";
      text = builtins.readFile ./containers_common_dist_config/seccomp.json;
    };

    # Generate policy.json with insecureAcceptAnything default
    policyJson = pkgs.writeTextFile {
      name = "policy-dist-conf";
      destination = "/share/containers/policy.json";
      text = builtins.toJSON {
        default = [
          { 
            type = "insecureAcceptAnything"; 
          }
        ];
      };
    };

    # Generate storage.conf based on the selected storage driver
    storageConf = pkgs.writeTextFile {
      name = "storage-dist-conf";
      # will end up under $out/
      destination = "/share/containers/storage.conf";
      # If using fuse-overlayfs, the config needs to be different.
      text = if cfgoptsdist.storage_driver == "fuse-overlay" then ''
        [storage]
        driver="overlay"
  
        [storage.options]
        mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
      '' else ''
        [storage]
        driver="${cfgoptsdist.storage_driver}"
      '';
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
        ++ lib.optional cfgoptsdist.policy policyJson
        ++ lib.optional (cfgoptsdist.storage_driver != null) storageConf
        # this one always needs to be included
        ++ [ containersConf ];
    };
  
  in {
    home.packages = []
      ++ lib.optional cfgopts.podman (wrapWithDistConfig pkgs.podman)
      ++ lib.optional cfgopts.skopeo (wrapWithDistConfig pkgs.skopeo);
  };
}

# vim: ts=2:sw=2:expandtab

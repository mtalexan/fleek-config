{ pkgs, misc, lib, config, options, ... }: {
  # Arbitrary config files go in here.

  # All the files/folders in here are in blocks that specify a common behavior, but are disabled by default.
  # They specify an options.custom.files.X.enable so they can conditionally be enabled in the host-specific
  # custom.nix.

  # Unlike the other files, which define things that are part of 'config' only and therefore don't need to
  # expliictly specify it, this file sets 'options' as well so everything else needs to indicate 'config'.

  # The main distrobox config.  Sets up for init and pre-init hooks.
  # The home.file.X.'text' option may be specified again in a host-specific custom.nix to add
  # extra host-specific values to it.
  options.custom.files.".config/distrobox/distrobox.conf" = with lib; {
    enable = mkEnableOption(lib.mdDoc "distrobox.conf file auto-population");
  };
  config.home.file.".config/distrobox/distrobox.conf" = {
    enable = config.custom.files.".config/distrobox/distrobox.conf".enable;
    executable = false;
    text =
      ''
        # support the init hooks (see home.file.distrobox_preinithooks)
        container_pre_init_hook="~/.config/distrobox/pre-init-hooks.sh"
        # support the init hooks (see home.file.distrobox_inithooks)
        container_init_hook="~/.config/distrobox/init-hooks.sh"
      '';
  };

  # Distrobox hooks structure as selected from a super set of standard hooks for
  # copying root CAs from the host into the distrobox, setting up nix within the distrobox,
  # etc.
  # Requires using the home_files/from_template.sh to coyp the template_distrobox into the
  # specific hostname folder, and then manually pruning it in the hostname folder.
  # Also requires setting home.file.".config/distrobox".source to point to the root of the
  # hostname-specific distrobox hooks folder.
  options.custom.files.".config/distrobox" = with lib; {
    enable = mkEnableOption(mdDoc "distrobox pre-init and init hooks");
  };
  config.home.file.".config/distrobox" = {
    # 'source' must be set in the custom.nix!
    #source = ./home_files/distrobox;

    enable = config.custom.files.".config/distrobox".enable;
    # keep the permissions from the files in the fleek folder
    executable = null;
    # Make each individual file a symlink in the copy rather than symlinking the
    # whole directory. We put other home.file's here too, so we can't do the
    # latter.
    recursive = true;
  };

  # The basic settings for podman.
  # Still requires uidmap to be installed manually from built-in package manager.
  # Pulled from Ubuntu.
  options.custom.files.".config/containers" = with lib; {
    enable = mkEnableOption(mdDoc "podman ubuntu-like registry and storage settings");
  };
  config.home.file.".config/containers" = {
    enable = config.custom.files.".config/containers".enable;
    executable = false;
    # Make each individual file a symlink in the copy rather than symlinking the
    # whole directory. We put other home.file's here too, so we can't do the
    # latter.
    recursive = true;
    source = ./home_files/podman_config;
  };

  # set of pre-defined short name aliases for images via podman
  options.custom.files.".config/containers/registries.conf.d/000-shortnames.conf" = with lib; {
    enable = mkEnableOption(mdDoc "podman predefined list of public image aliases");
  };
  config.home.file.".config/containers/registries.conf.d/000-shortnames.conf" = {
    enable = config.custom.files.".config/containers/registries.conf.d/000-shortnames.conf".enable;
    executable = false;
    text = ''
      [aliases]
        # almalinux
        "almalinux" = "docker.io/library/almalinux"
        "almalinux-minimal" = "docker.io/library/almalinux-minimal"
        # containers
        "skopeo" = "quay.io/skopeo/stable"
        "podman" = "quay.io/podman/stable"
        # docker
        "alpine" = "docker.io/library/alpine"
        "docker" = "docker.io/library/docker"
        "registry" = "docker.io/library/registry"
        # Fedora
        "fedora-minimal" = "registry.fedoraproject.org/fedora-minimal"
        "fedora" = "registry.fedoraproject.org/fedora"
        # openSUSE
        "opensuse/tumbleweed" = "registry.opensuse.org/opensuse/tumbleweed"
        "tumbleweed" = "registry.opensuse.org/opensuse/tumbleweed"
        # SUSE
        "suse/sle15" = "registry.suse.com/suse/sle15"
        "sle15" = "registry.suse.com/suse/sle15"
        # Red Hat Enterprise Linux
        "rhel" = "registry.access.redhat.com/rhel"
        "rhel6" = "registry.access.redhat.com/rhel6"
        "rhel7" = "registry.access.redhat.com/rhel7"
        "ubi7" = "registry.access.redhat.com/ubi7"
        "ubi7-init" = "registry.access.redhat.com/ubi7-init"
        "ubi7-minimal" = "registry.access.redhat.com/ubi7-minimal"
        "ubi8" = "registry.access.redhat.com/ubi8"
        "ubi8-minimal" = "registry.access.redhat.com/ubi8-minimal"
        "ubi8-init" = "registry.access.redhat.com/ubi8-init"
        "ubi8-micro" = "registry.access.redhat.com/ubi8-micro"
        "ubi8/ubi" = "registry.access.redhat.com/ubi8/ubi"
        "ubi8/ubi-minimal" = "registry.access.redhat.com/ubi8-minimal"
        "ubi8/ubi-init" = "registry.access.redhat.com/ubi8-init"
        "ubi8/ubi-micro" = "registry.access.redhat.com/ubi8-micro"
        # Debian
        "debian" = "docker.io/library/debian"
        # Ubuntu
        "ubuntu" = "docker.io/library/ubuntu"
        # Oracle Linux
        "oraclelinux" = "container-registry.oracle.com/os/oraclelinux"
        # busybox
        "busybox" = "docker.io/library/busybox"
        # php
        "php" = "docker.io/library/php"
        # python
        "python" = "docker.io/library/python"
        # node
        "node" = "docker.io/library/node"
    '';
  };
}

# vim: sw=2:expandtab
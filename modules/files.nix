{ pkgs, misc, lib, config, options, ... }: {
  # Arbitrary config files go in here.

  # All the files/folders in here are in blocks that specify a common behavior, but are disabled by default.
  # They specify an options.custom.files.X.enable so they can conditionally be enabled in the host-specific
  # custom.nix.

  # Unlike the other files, which define things that are part of 'config' only and therefore don't need to
  # expliictly specify it, this file sets 'options' as well so everything else needs to indicate 'config'.

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
  # framing support. Currently setup of 0.75.0.
  # Shell integration does not require AppImage installation, it can be added to a remote system so that when connecting
  # it gets used.
  #   enableAppImage : T/F : Installs the AppImage as 'extraterm' in ~/.local/bin and adds the GUI-related files.
  #   enableBashIntegration : T/F : Adds sourcing of the shell integration scripts needed for framing, 'from', and 'show' commands to bashrc
  #   enableZshIntegration : T/F : Adds sourcing of the shell integration scripts needed for framing, 'from', and 'show' commands to zshrc
  options.custom.extraterm.config = with lib; {
    # app image is broken
    #enableAppImage = mkEnableOption(mdDoc "Enable extraterm AppImage in the ~/.local/bin (PATH) as 'extraterm'");
    # WARNING: this integration causes extraterm to be unable to run subshells
    enableBashIntegration = mkEnableOption(mdDoc "Enable bash integration required for framing and 'from' and 'show' commands.");
    enableZshIntegration = mkEnableOption(mdDoc "Enable zsh integration required for framing and 'from' and 'show' commands.");
  };

  # AppImage doesn't work as a technology for terminals since it nests a new environment that masks some of the host
  #config.home.file.".local/bin/extraterm" = {
  #  enable = config.custom.extraterm.config.enableAppImage;
  #  executable = true;
  #  source = ../home_files/extraterm/ExtratermQt-0.75.0.glibc2.34-x86_64.AppImage;
  #};
  #
  #config.home.file.".local/share/extraterm/icon.png" = {
  #  enable = config.custom.extraterm.config.enableAppImage;
  #  executable = true;
  #  source = ../home_files/extraterm/icon.png;
  #};
  #config.home.file.".local/share/applications/Extraterm-0.75.0.desktop" = {
  #  enable = config.custom.extraterm.config.enableAppImage;
  #  executable = false;
  #  text = ''
  #    #!/usr/bin/env xdg-open
  #    [Desktop Entry]
  #    Version=0.75.0
  #    Terminal=false
  #    Type=Application
  #    Name=Extraterm
  #    Comment=Extraterm terminal emulator
  #    Exec=~/.local/bin/extraterm
  #    Icon=~/.local/share/extraterm/icon.png
  #    Categories=Utility
  #  '';
  #  # register the desktop file when it gets updated/changed.
  #  # Try 'update-desktop-database' if it exists, otherwise try 'xdg-desktop-menu'
  #  onChange = ''
  #    if command -v update-desktop-database &>/dev/null; then
  #      update-desktop-database ~/.local/share/applications
  #    elif command -v xdg-desktop-menu &>/dev/null ; then
  #      xdg-desktop-menu install --mode user $HOME/.local/share/applications/Extraterm-0.75.0.desktop
  #    fi
  #  '';
  #};

  config.home.file.".config/extraterm/integrations" = {
    enable = config.custom.extraterm.config.enableBashIntegration || config.custom.extraterm.config.enableZshIntegration;
    recursive = false; # symlink the whole folder, not each file in it
    # let execute bit be defined individually by the files in the linked directory
    source = ../home_files/extraterm/extraterm-commands-0.75.0;
  };
  config.programs.bash.initExtra = (lib.mkIf config.custom.extraterm.config.enableBashIntegration
     (lib.concatLines [
      "source $HOME/.config/extraterm/integrations/setup_extraterm_bash.sh"
    ])
  );
  config.programs.zsh.initExtra = (lib.mkIf config.custom.extraterm.config.enableZshIntegration
    (lib.concatLines [
      "source $HOME/.config/extraterm/integrations/setup_extraterm_zsh.zsh"
    ])
  );
}

# vim: sw=2:expandtab
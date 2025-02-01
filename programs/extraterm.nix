{ pkgs, misc, lib, config, options, ... }: {
  # Arbitrary config files go in here.

  # All the files/folders in here are in blocks that specify a common behavior, but are disabled by default.
  # They specify an options.custom.files.X.enable so they can conditionally be enabled in the host-specific
  # custom.nix.

  # Unlike the other files, which define things that are part of 'config' only and therefore don't need to
  # expliictly specify it, this file sets 'options' as well so everything else needs to indicate 'config'.

  # ALSO SEE:
  #  modules/nixgl.nix
  #  programs/distrobox.nix


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

# vim: ts=2:sw=2:expandtab
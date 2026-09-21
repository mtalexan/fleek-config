{ lib, ... }: {
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
}
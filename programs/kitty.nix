{ pkgs, misc, lib, ... }: {
  # A terminal multiplexer with lots of features, but also high speed

  # manual kitty integration into the shell is required since automatic injection doesn't work for subshells, multiplexers, etc
  # See https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
  programs.zsh.initExtra = ''
    if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="enabled"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
    fi
  '';
  programs.bash.initExtra = ''
    if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="enabled"
        source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
    fi
  '';

  programs.kitty = {
    enable = false;
    shellIntegration = {
      # Since automatic shell integration doesn't work in subshells, multiplexers, etc, we have to manually detect and load the code ourselves
      # as part of the rc file
      mode = "disabled";
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
    #environment = {
    #  "LS_COLORS" = "1";
    #};
    #font = {
    #  package = pkgs.nerdfonts;
    #  name = ???;
    #  size = ???;
    #};
    #keybindings = {
    #  "ctrl+c" = "copy_or_interrupt";
    #  "ctrl+f>2" = "set_font_size 20";
    #};
    #settings = {
    #  scrollback_lines = 999999;
    #  enable_audio_bell = false;
    #  update_check_interval = 0;
    #};

    # See theme options with 'kitty +kitten themes'
    #theme = ;
  };
}

# vim: sw=2:expandtab
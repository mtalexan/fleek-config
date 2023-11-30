{ pkgs, misc, lib, ... }: {
  programs.tmux = {
    enable = true;
    # automatically includes the tmux-sensible plugin, which adapts some common options
    # https://github.com/tmux-plugins/tmux-sensible

    historyLimit = 10000000;
    keyMode = "emacs";
    mouse = true;

    # Allow tmux layouts, startup/exit behaviors, etc to be pre-defined in YAML.
    # https://github.com/tmuxinator/tmuxinator
    # Stores the settings (with --local) in .tmuxinator.yaml in the current folder
    # Create a new project (multiple allowed per file)
    #   tmuxinator new --local [project]
    # Start a tmux session from the project:
    #   tmuxinator start --local [project]
    tmuxinator.enable = true;

    #plugins = with pkgs; [
    #  # tmux-sensible always included automatically
    #  tmuxPlugins.
    #];
  };
}

# vim: sw=2:expandtab

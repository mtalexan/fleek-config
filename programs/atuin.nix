{ pkgs, misc, lib, ... }: {
  programs.atuin = {
    enable = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      auto_sync = false;
      # fzf-style search syntax
      search_mode = "fuzzy";
      # look at history of just the one session by default, hitting Ctrl+R again will give host
      filter_mode = "session";
      # when pressing up-key, only look in the session
      filter_mode_shell_up_key_binding = "session";
      # other formats take up more space and count towards the inline_height
      style = "compact";
      inline_height = 10;
      # don't show an extra help line
      show_help = false;
      # show a preview of the full command
      show_preview = true;
      # return-original doesn't work, it always wipes it
      exit_mode = "return-query";
    };
  };
}

# vim: sw=2:expandtab

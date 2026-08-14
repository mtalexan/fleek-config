{ pkgs, misc, lib, config, ... }: {
  home.programs.broot = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      # show git status, show hidden, don't obey ignores
      default_flags = "-ghi";

      special_paths = {
        # hide .git folders and don't enter them. Needed since we don't obey VCS ignores
        "**/.git" = {
          show = "never";
          list = "never";
          sum = "never";
        };
      };

      lines_before_match_in_preview = 2;
      lines_after_match_in_preview = 2;
    };
  };
};
{ pkgs, misc, lib, config, ... }: {
 
  programs.broot = {
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

      verbs = [
        # don't jump to opposite top/bottom when hitting the limit
        {
          key = "up";
          internal = ":line_up_no_cycle";
        }
        {
          key = "down";
          internal = ":line_down_no_cycle";
        }

        # input word navigation
        
        
        # ergo keys as arrows
        {
          key = "alt-i";
          internal = ":line_up_no_cycle";
        }
        {
          key = "alt-shift-i";
          internal = ":page_up";
        }

        {
          key = "alt-k";
          internal = ":line_down_no_cycle";
        }
        {
          key = "alt-shift-k";
          internal = ":page_down";
        }
        
        {
          key = "alt-j";
          internal = ":input_go_left";
        }
        {
          key = "alt-l";
          internal = ":input_go_right";
        }
        
        {
          key = "alt-u";
          internal = ":input_go_to_start";
        }
        {
          key = "alt-o";
          internal = ":input_go_to_end";
        }
        {
          key = "ctrl-alt-j";
          internal = ":panel_left_no_open";
        }
        {
          key = "ctrl-alt-l";
          internal = ":panel_right";
        }

        # remap some toggles we overrode in ergo mode
        {
          key = "ctrl-i";
          internal = ":toggle_ignore";
        }
        {
          key = "ctrl-h";
          internal = ":toggle_hidden";
        }

        # hide/show preview
        {
          key = "alt-/";
          internal = ":toggle_preview";
        }

        # basic word delete (backspace)
        {
          key = "ctrl-delete";
          internal = ":input_del_word_left";
        }

        # close the current panel
        {
          key = "ctrl--";
          internal = ":close_panel_cancel";
        }
      ];
    };
  };
}
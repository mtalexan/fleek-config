{ pkgs, misc, lib, ... }: {
  # TODO: populate this so the Nix one is available on the system. Use nixGL in the calls.
  #xdg.desktopEntries = {};

  programs.terminator = {
    enable = true;
    config = {
      global_config = {
        borderless = false;
        tab_position = "bottom";
        scroll_tabbar = true;
        homogeneous_tabbar = false;
        title_hide_sizetext = true;
        inactive_color_offset = 0.66;
        enabled_plugins = "ActivityWatch, InactivityWatch, LaunchpadBugURLHandler, LaunchpadCodeURLHandler, APTURLHandler";
        always_split_with_profile = true;
        title_use_system_font = false;
        title_font = "DejaVuSansM Nerd Font Mono Regular 12";
        focus = "system";
      };
      keybindings = {
        zoom_in = "<Primary>plus";
        zoom_out = "<Primary>underscore";
        zoom_normal = "";
        cycle_next = "";
        cycle_prev = "";
        go_next = "";
        go_prev = "";
        go_up = "<Super>i";
        go_down = "<Super>k";
        go_left = "<Super>j";
        go_right = "<Super>l";
        rotate_cw = "";
        rotate_ccw = "";
        split_horiz = "<Alt>2";
        split_vert = "<Alt>3";
        close_term = "<Alt>minus";
        copy = "<Primary><Shift>Delete";
        paste = "<Primary><Shift>Insert";
        toggle_scrollbar = "";
        page_up = "<Shift>Page_Up";
        page_down = "<Shift>Page_Down";
        line_up = "<Shift>Up";
        line_down = "<Shift>Down";
        close_window = "";
        resize_up = "";
        resize_down = "";
        resize_left = "";
        resize_right = "";
        move_tab_right = "";
        move_tab_left = "";
        toggle_zoom = "";
        scaled_zoom = "";
        next_tab = "<Super>n";
        prev_tab = "<Super>p";
        reset = "";
        reset_clear = "";
        hide_window = "";
        group_all = "";
        ungroup_all = "";
        group_tab = "";
        ungroup_tab = "";
        new_window = "<Primary><Shift>t";
        new_terminator = "";
        insert_number = "";
        insert_padded = "";
        edit_window_title = "F9";
        edit_tab_title = "";
        edit_terminal_title = "";
        layout_launcher = "";
        broadcast_off = "";
        broadcast_group = "";
        broadcast_all = "";
        new_tab = "<Primary><Shift>n";
      };
      profiles = {
        default = {
          audible_bell = true;
          visible_bell = false;
          urgent_bell = true;
          background_color = "#002b36";
          cursor_blink = false;
          cursor_color = "#d85d5d";
          foreground_color = "#839496";
          show_titlebar = true;
          scrollbar_position = "hidden";
          scrollback_infinite = true;
          palette = "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3";
          word_chars = "-,./?%&#_~:";
          use_system_font = false;
          copy_on_selection = true;
          split_to_group = true;
          font = "DejaVuSansM Nerd Font Mono Regular 11";
        };
      };
      layouts = {
        default = {
          child1 = {
            parent = "window0";
            profile = "default";
            type = "Terminal";
          };
          window0 = {
            parent = "";
            type = "Window";
          };
        };
      };
      plugins = {};
    };
  };
}

# vim: ts=2:sw=2:expandtab

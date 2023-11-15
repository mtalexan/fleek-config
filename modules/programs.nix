
# Programs that aren't the shell or the prompt are in here
let
  # for fake hash, use "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  vimPluginFromGitHub = owner: repo: rev: hash: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName "${owner}/${repo}"}";
    version = "${rev}";
    src = pkgs.fetchFromGitHub {
      owner = "${owner}";
      repo = "${repo}";
      rev = "${rev}";
      hash = "${hash}";
    };
  };
in
{
  programs.atuin = {
    enable = true;
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

  programs.bat = {
    enable = true;
    config = {
      # theme is reused by git-delta.
      # preview all available themes when applied to a file with: 
      #  bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"
      theme = "Visual Studio Dark+";
      map-syntax = [
        "*.jenkinsfile:Groovy"
        "*.props:Java Properties"
        "*.incl:Bourne Again Shell (bash)"
      ];
      # bat really wants this to be the pager and auto-sets the correct options to it,
      # so make it explicit.
      pager = "less";
    };
    # extra command-line commands that wrap common uses of bat
    extraPackages = with pkgs.bat-extras; [
      # diffs
      batdiff
      # man pages
      batman
      # use for grep/ripgrep (limited rg options)
      batgrep
      # pretty-print code from a file
      prettybat
    ];
  };

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    # set explicitly instead for clarity
    #enableAliases = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = lib.concatStringsSep " " [
      "fd" 
      "--type f" 
      "--hidden" 
      "--follow" 
      "--exclude '.git'" 
      "."
    ];
    defaultOptions = [
      #"--layout=default"
      # ergo-key bindings using alt
      "--bind 'ctrl-/:toggle-preview,alt-bs:backward-kill-word,alt-j:backward-char,alt-l:forward-char,alt-i:up,alt-k:down,alt-J:backward-word,alt-L:forward-word,alt-I:page-up,alt-K:page-down,ctrl-g:cancel,alt-u:beginning-of-line,alt-o:end-of-line,ctrl-n:next-history,ctrl-p:previous-history,ctrl-]:jump,alt-space:toggle-in,ctrl-space:toggle-in,ctrl-alt-k:preview-down,ctrl-alt-i:preview-up,ctrl-alt-I:preview-page-up,ctrl-alt-K:preview-page-down'"
      "--border=sharp"
      "--info=inline"
      "--height=30%"
      "--min-height=10"
      "--layout=reverse"
      "--ansi"
      "--tabstop=4"
      "--color=dark"
      "--cycle"
    ];
    # Alt+C command, look for directories
    changeDirWidgetCommand = lib.concatStringsSep " " [
      "fd" 
      "--type d" 
      "--hidden" 
      "--follow"
      "--exclude '.git'"
      "."
    ];
    changeDirWidgetOptions = [
      "--preview 'eza --tree -L 2 --color=always {}'"
      "--preview-window right,border-vertical"
      "--bind 'ctrl-/:toggle-preview'"
      "--scheme=path"
      "--filepath-word"
      "--multi"
    ];
    # Ctrl+T command
    fileWidgetCommand = lib.concatStringsSep " " [
      "fd" 
      "--type f" 
      "--hidden"
      "--follow"
      "--exclude '.git'"
      "."
    ];
    fileWidgetOptions = [
      "--preview 'bat -n --color=always -r :500 {}'"
      "--preview-window right,border-vertical"
      "--bind 'ctrl-/:toggle-preview'"
      "--scheme=path"
      "--filepath-word"
      "--multi"
    ];
  };

  # some per-system config is in the {system-name}/{username}.nix file
  programs.git = {
    aliases = {
      unstage = "restore --staged";
      #added by default because it's so common
      #graph = "log --oneline --decorate --graph";
      co = "checkout";
      cm = "commit";
      bvv = "branch -vv";
      last = "log -1 HEAD";
      update = "pull --no-rebase --ff --no-commit --ff-only";
    };
    delta = {
      # automatically sets itself as the pager for git
      # and the interactive.diffFilter
      enable = true;
      options = {
        # these options have to be put under a separate feature name so they don't get applied
        # when using 'git add -i' or 'git add -p', that requires a specific text input format.
        decorations = {
          side-by-side = true;
          # files in listings need a box
          file-style = "bold yellow box";
        };
        features = "decorations";
        # themese are set to mirror bat automatically
        line-numbers = true;
        navigate = true;
        hyperlinks = true;
        # this causes it to open in vscode when hyperlinks to commits are clicked
        hyperlinks-file-link-format = "vscode://file/{path}:{line}" ;
        # use relative paths for all file names
        relative-paths = true;
        # tab display width
        tabs = 4;
        # header blocks only extend to the end of the file section and not the entire terminal width
        width = "variable";
      };
    };
    extraConfig = {
      diff = {
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };
      merge = {
        conflictStyle = "diff3";
      };
    };
    lfs = {
      enable = true;
    };
  };

  programs.jq.enable = true;

  programs.less = {
    enable = true;
    # keys = ''
    #
    #'';
  };

  # also adds the man pages for home-manager
  programs.man = {
    enable = true;
    # a bit slower when home-manager creates new generations, but helpful
    generateCaches = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = false;

    # bug in some versions of home-manager requires this to be set to something for plugins to get parsed
    extraConfig = ''

    '';

    extraLuaConfig = lib.concatLines [
      "vim.opt.backup = false"
      "vim.opt.relativenumber = true"
      "vim.opt.syntax = on"
    ];

    # plugins can be from nixpkgs vimPlugins.*
    # or can be from gitHub by using the custom function define in the let at the top of
    # this file, vimPluginFromGitHub
    plugins = with pkgs.vimPlugins; [
      # needed by barbar-nvim and lualine-nvim for icons
      nvim-web-devicons

      # tabs for buffers
      barbar-nvim

      # nicer mode line
      {
        plugin = lualine-nvim;
        config = ''
          lua require('lualine').setup({options={theme='vscode'}})
        '';
      }

      # use nix precompiled grammars
      nvim-treesitter.withAllGrammars

      {
        # latest rev as of 2023-08-01
        plugin = (vimPluginFromGitHub "Mofiqul" "vscode.nvim" "05973862f95f85dd0564338a03baf61b56e1823f" "sha256-iY3S3NnFH80sMLXgPKNG895kcWpl/IjqHtFNOFNTMKg=");
        config = ''
          :colorscheme vscode
        '';
      }
    ];
  };

  # supplies the command-not-found hook to tell about nix packages
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # notifies of completed commands. Can also Ctrl+Z a command and then add noti to it with:
  #   fg; noti
  # Always includes banner notifications, but can include Telegram, Slack, Zulip, whatever
  # if configured.
  programs.noti = {
    enable = true;
    # settings = {
    #  # see   https://github.com/variadico/noti/blob/main/docs/noti.md#configuration
    #};
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      # Search hidden files / directories (e.g. dotfiles) by default
      "--hidden"
      # Don't include .git folders.  Requires explicit --glob override on the CLI if we do want to search it
      "--glob=!.git/*"
    ];
  };


  # a quick script calling tool from a sub-directory of scripts
  # https://github.com/ianthehenry/sd
  programs.script-directory = {
    enable = true;
    settings = {
      # within the home-manager config folder, ~/.local/share/fleek/sd_scripts.
      # This makes the folder and all files in it part of the nix package automatically, and 
      # uses a path relative to the home-manager root file (flake.nix)
      SD_ROOT = "${./sd_scripts}";
      # defaults to EDITOR or VISUALEDITOR if not set
      SD_EDITOR = "nvim";
      # defaults to 'cat' if not set
      SD_CAT = "bat";
    };
  };

  # a Rust-based tldr program
  programs.tealdeer = {
    enable = true;
    # see https://dbrgn.github.io/tealdeer/config.html
    settings = {
      display = {
        use_pager = true;
        compact = false;
      };
      # style = {};
      updates = {
        auto_update = true;
        # auto_update_interval = 720; # default
      };
      # directories = {};
    };
  };

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
        title_font = "DejaVu Sans Mono for Powerline 12";
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
          font = "DejaVuSansMono Nerd Font 11";
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

  # 'z' and 'zi' commands for directory jumps based on frecency.  
  # Uses fzf to select options if using 'z <pattern> '+tab
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # options to pass to the 'zoxide init' command
    options = [
      # update directory scores on every folder change
      "--hook=pwd"
      # replace the cd command with zoxide if set.  Default is 'z' and 'zi'
      #"--cmd=cd"
    ];
    # The following environment variables have to be set manually in the home.sessionVariables
    # _ZO_ECHO = 1 ; to print matched dir before jumping
    # _ZO_EXCLUDE_DIRS = dir:dir:dir ; list of ':' separated dirs to ignore
    # _ZO_FZF_OPTS = <opts>; options to pass to fzf when opening it for match selection
    # _ZO_MAXAGE = 10000; maximum number of entries in the database
    # _ZO_RESOLVE_SYMLINKS = 1; to resolve symlinks before adding to the database
  };
}

# vim: sw=2:expandtab
{ pkgs, misc, lib, ... }: 
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 
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
        tab_position = bottom;
        scroll_tabbar = true;
        homogeneous_tabbar = false;
        title_hide_sizetext = true;
        inactive_color_offset = 0.66;
        enabled_plugins = [
          ActivityWatch
          InactivityWatch
          LaunchpadBugURLHandler
          LaunchpadCodeURLHandler
          APTURLHandler
        ];
        always_split_with_profile = true;
        title_use_system_font = false;
        title_font = DejaVu Sans Mono for Powerline 12;
        focus = system;
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
          font = DejaVuSansMono Nerd Font 11;
        };
      };
      layouts = {
        default = {
          child1 = {
            parent = window0;
            profile = default;
            type = Terminal;
          };
          window0 = {
            parent = "";
            type = Window;
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

  ####################################################################################
  # prompt

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      # Prompt preceeding where you type.
      #
      # Defines 2-4 lines.  First line uses $fill to separate left and right halves.
      # WARNING: The right side of all lines must end in a space if $fill-ing becauase the right_prompt adds one for some reason.
      # WARNING: $all will always evaluate to something, so using "(|$all|)" will always end up as "||"
      # TODO: curently no way to add "$fill[─┤ ](base_lines)" to the end of lines 2 and 3 without
      #       making them always show up
      format = lib.concatStrings [
        "[╭─](base_lines)"
        "$shell"
        "($username@$hostname)($container)"
        "$directory"
        "$fill"
        "$status"
        "$cmd_duration"
        "$time"
        "[─╮ ](base_lines)\n"
        ""
        "([├─](base_lines)"
        "($vcsh )"
        "($hg_branch )"
        "($fossil_branch )"
        "($pijul_channel )"
        "(($git_branch)($git_commit)( $git_status)( $git_state) )"
        "\n)"
        ""
        "([├─](base_lines)"
        "($package)"
        "($conda)"
        "($meson)"
        "($ocaml)"
        "($python)"
        "($nix_shell)"
        "\n)"
        ""
        "[╰─](base_lines)($jobs|)$shlvl$character"
      ];
      # Prompt to the right of where you type.
      right_format = "[─╯](base_lines)";

      # Disable the blank line at the start of the prompt
      # add_newline = false;
      add_newline = true;
      # A continuation prompt that displays two filled in arrows
      continuation_prompt = "[▶▶](base_lines) ";

      # use the palettes.global key for defining new colors
      palette = "global";

      palettes.global = {
        # can't reference other new names in here

        # global colors
        git_commitish = "green";  #branch, tag, or commit;
        git_stateish = "bold yellow"; #REBASING, MERGING, etc;
        git_statusish = "#af8700"; # mustard. #extra local/remote commits, etc;
        base_lines = "grey dim"; # lines around the prompts;
        directory_default = "blue";
        # new color names
        mustard = "#af8700";
      };

      character = {
        success_symbol = "[❯](bold green)";
        #error_symbol = "[✗](bold red)";
        disabled = false;
      };

      fill = {
        symbol = "─";
        style = "base_lines";
        disabled = false;
      };

      line_break = {
        # only useful if you want to add $line_break into your format, but doesn't seem to actually work
        disabled = true;
      };

      ###### Utilities
      
      battery = {
        disabled = true;
      };

      cmd_duration = {
        min_time = 1000; # in ms
        show_milliseconds = false;
        style = "#a79776";
        format = "[ $duration]($style) ";
        disabled = false;
      };

      directory = {
        # something very long
        truncation_length = 7;
        truncation_symbol = "…/";
        # don't always truncate to the root of the repo
        truncate_to_repo = false;
        format = "[ $path ]($style)[$read_only]($read_only_style) ";
        repo_root_format = "[ $before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style)";
        style = "directory_default";
        before_repo_root_style = "directory_default";
        repo_root_style = "underline directory_default";
        read_only = "🔒";
        read_only_style = "red";
        disabled = false;
      };

      #env_var = {
      #  #default here
      #  foo = {
      #    #foo-specific variable settings here
      #  };
      #};

      hostname = {
        ssh_only = true;
        ssh_symbol = "ࣀ ";
        disabled = false;
      };

      jobs = {
        # shows number of background jobs as either sybmbol, number, or both
        symbol_threshold = 1;
        number_threshold = 1;
        format = "[$symbol$number]($style)";
        disabled = false;
      };

      localip = {
        disabled = true;
      };

      memory_usage = {
        symbol = "󰍛 ";
        disabled = true;
      };

      os = {
        disabled = true;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
        };
      };

      shell = {
        # Only going to use it if the shell isn't the default,
        # since it's likely starship will be available for more than one shell.
        # Uncomment only the one that is the default shell
        #bash_indicator = "";
        #fish_indicator = "";
        zsh_indicator = "";
        #powershell_indicator = "";
        #ion_indicator = "";
        #elvish_indicator = "";
        #tcsh_indicator = "";
        #xonsh_indicator = "";
        #cmd_indicator = "";
        #nu_indicator = "";
        #unknown_indicator = "";
        format = "([$indicator]($style))";
        disabled = false;
      };

      shlvl = {
        # WARNING: The detection logic is off-by-one in bash: https://github.com/starship/starship/issues/2407
        threshold = 2;
        repeat = true; # repeat symbol for the number of levels
        ## Decreases the repeat count by repeat_offset and doesn't show if it comes out to 0 or less
        repeat_offset = 1;
        style = "white bold";
        symbol = "❯";
        format = "[$symbol]($style)";
        disabled = false;
      };

      status = {
        #success_symbol = "✔";
        success_symbol = ""; # make it empty to not show anything on success
        symbol = "✘"; # the generic symbol, specific symbols for known codes can be set with map_symbol
        recognize_signal_code = true; # report signal names instead of numbers
        map_symbol = false; # use special symbols for known codes
        pipestatus = true; # report pipeline status a series of pipe-separated results
        style = "bold red";
        format = "[$symbol $signal_name$common_meaning$maybe_int]($style)";
        # used when pipestatus=true and pipeline status returns
        pipestatus_format = "(\\[$pipestatus\\]=>[$symbol $signal_name$common_meaning$maybe_int]($style))";
        pipestatus_segment_format = "[$status]($style)";
        disabled = false;
      };

      sudo = {
        # displays when sudo credentials are cached
        disabled = true;
      };

      time = {
        time_format = "%T"; # Hour:Minute:Second Format
        use_12hr = false;
        utc_time_offset = "local";
        style = "#768987";
        format = "[  $time ]($style)";
        disabled = false;
      };

      username = {
        # only show for root, and remote connections
        show_always = false;
        style_root = "bold red";
        style_user = "bold yellow";
        format = "[$user]($style)";
        disabled = false;
      };

      ###### git

      git_branch = {
        symbol = "";
        format = "[  $branch]($style)";
        style = "git_commitish";
        only_attached = true;
        disabled = false;
      };

      git_commit = {
        format = "[ @$hash( \\($tag\\))]($style) ";
        style = "git_commitish";
        # only show commit if we don't have a branch name
        only_detached = true;
        # try to get a tag name if we're stuck without a branch
        tag_disabled = false;
        disabled = false;
      };

      git_metrics = {
        disabled = true;
      };

      git_state = {
        style = "git_stateish";
        format = "[$state(\\($progress_current/$progress_total\\))]($style)";
        disabled = false;
      };

      git_status = {
        style = "git_statusish";
        format = "[$all_status$ahead_behind]($style)";
        ahead = "[⇡$count](green)";
        behind = "[⇣$count](red)";
        diverged = "[⇡$ahead_count](green)[⇣$behind_count](red)";
        conflicted = "= $count";
        up_to_date = "";
        untracked = "?$count";
        stashed = "\$$count";
        modified = "!$count";
        staged = "+$count";
        renamed = "»$count";
        deleted = "✘$count";
        typechanged = "";
        ignore_submodules = false;
        disabled = false;
      };

      ###### Languages
      # Only languages I care about are configured, all others are disabled for optimization

      aws = {
        symbol = " ";
        format = "[$symbol($profile)( \\($region\\))( \\[$duration\\])]($style) ";
        disabled = true;
      };

      azure = {
        symbol = " ";
        format = "[$symbol($subscription)]($style) ";
        disabled = true;
      };

      conda = {
        symbol = "🐍 ";
        format = "([$symbol $environment]($style) )";
        disabled = false;
      };

      container = {
        # if inside a container that has starship installed.
        # Only really applies to toolbx or distrobx
        #symbol = "🛠 ";
        format = "([\\[$name\\]]($style)) ";
        disabled = false;
      };

      docker_context = {
        # for docker swarms
        format = "[$symbol$context]($style) ";
        disabled = true;
      };

      dotnet = {
        symbol = " ";
        format = "[$symbol($version)( 🎯 $tfm )]($style) ";
        disabled = true;
      };

      elixir = {
        format = "[$symbol($version( \\(OTP $otp_version\\)))]($style) ";
        disabled = true;
      };

      fossil_branch = {
        style = "git_commitish";
        format = "([$symbol$branch]($style) )";
        disabled = false;
      };

      gcloud = {
        format = "([$symbol$account(@$domain)(\\($region\\))]($style)) ";
        disabled = true;
      };

      guix_shell = { # can nly show a symbol
        format = "[$symbol]($style) ";
        disabled = true;
      };

      hg_branch = {
        # Mercurial Bracnh
        style = "git_commitish";
        format = "([$symbol$branch(:$topic)]($style) )";
        disabled = false;
      };

      kubernetes = {
        format = "[$symbol$context(\\($namespace\\))]($style) ";
        disabled = true;
      };

      meson = {
        format = "[$symbol$project]($style) ";
        disabled = false;
      };

      nix_shell = {
        format = "[$symbol$state( \\($name\\))]($style) ";
        # don't set heuristic = true, it detects the nix-profile of home-manager as a shell
        heuristic = false; # try to detect "nix shell" style shells too?
        disabled = false;
      };

      ocaml = {
        format = "[$symbol($version)( \\($switch_indicator$switch_name\\))]($style) ";
        disabled = false;
      };

      openstack = {
        format = "[$symbol$cloud(\\($project\\))]($style) ";
        disabled = true;
      };

      package = {
        # when in a package directory for any of a long list of languages,
        # including poetry
        symbol = "📦"; # doesn't need trailing space
        format = "[$symbol $version]($style) ";
        disabled = false;
      };

      pijul_channel = {
        format = "([$symbol$channel]($style) )";
        disabled = false;
      };

      pulumi = {
        format = "[$symbol($username@)$stack]($style) ";
        disabled = true;
      };

      python = {
        #symbol = " "; # use the one that looks like  snake
        symbol = "🐍"; #doesn't need trailing space
        format = "([$symbol $virtualenv]($style) )";
        python_binary = ["python3" "python"];
        detect_folders = [".venv"];
        disabled = false;
      };

      singularity = {
        format = "([$symbol\\[$env\\]]($style) )";
        disabled = true;
      };

      spack = {
        format = "[$symbol$environment]($style) ";
        disabled = true;
      };

      ###### Plugins only showing versions of global tools

      buf = {
        symbol = " ";
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      bun = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      c = {
        symbol = " ";
        format = "[$symbol($version(-$name))]($style) ";
        disabled = true; # don't need toolchain info
      };

      cmake = {
        format = "[$symbol($version)]($style) ";
        disabled = true; # don't need cmake version
      };

      cobol = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      crystal = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      daml = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      dart = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      deno = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      elm = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      erlang = {
        foramt = "[$symbol($version)]($style) ";
        disabled = true;
      };

      fennel = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      golang = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      gradle = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      haskell = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      haxe = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      helm = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      java = {
        format = "[$symbol($version)]($style)";
        disabled = true;
      };

      julia = {
        symbol = " ";
        format = "[$symbol($version )]($style) ";
        disabled = true;
      };

      kotlin = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      lua = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      nim = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      nodejs = {
        format = "[$symbol($version)]($style) ";
        disabled = false;
      };

      opa = {
        # open policy agent
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      perl = {
        # don't need the perl version
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      php = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      purescript = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      rlang = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      raku = {
        format = "[$symbol($version-$vm_version)]($style) ";
        disabled = true;
      };

      red = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      ruby = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      rust = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      scala = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      solidity = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      swift = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      terraform = {
        # WARNING: using this is apparently slow to calculate version
        format = "[$symbol$workspace]($style) ";
        disabled = true;
      };

      vagrant = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      vlang = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };

      vcsh = {
        format = "[$symbol$repo]($style) ";
        disabled = false;
      };

      zig = {
        format = "[$symbol($version)]($style) ";
        disabled = true;
      };
    };
  };

  ##########################################################################################
  # shell

  # shared shell settings
  home = {
    # WARNING: by default all sessionVariables are only sourced once at login.
    #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
    sessionVariables = {
      GCC_COLORS = "error=01;31;warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
      SUDOEDITOR = "nvim";
      GIT_EDITOR = "nvim";
      # use options like FZF changeDir (Alt+C) display options
      _ZO_FZF_OPTS = lib.concatStringsSep " " [
        # 'zoxide -i' always passes the score then the folder name with some leading indentation.
        # Carefully echo the string, parse it thru awk to get only the second column, and then use
        # the result in an eza --tree command that shows colors and only 2 dirs deep in each tree
        "--preview 'eza --tree -L2 --color=always \\$( echo {} | awk '\\''{ print \\$2 }'\\'')'"
        "--preview-window right,border-vertical" 
        "--bind 'ctrl-/:toggle-preview'"
        "--scheme=path"
        "--filepath-word"
        "--multi" 
        "--info=inline"
        "--border=sharp" 
        # let it be taller than fzf history, but not fullscreen like changeDir
        "--height=50%" 
        "--tabstop=4" 
        "--color=dark" 
        "--cycle" 
        "--layout=reverse"
      ];
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;

    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
      "progcomp"
    ];

    historyControl = [
      "ignoredups"
      "ignorespace"
    ];

    # already in fleek
    # profileExtra = "[ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh";
    # initExtra = "source <(fleek completion bash)";
    initExtra = lib.concatLines [
      # bash has a bug where it somehow evaluates and prints SHLVL in a subshell as off-by-one for the first
      # subshell.  We can't actually detect whether we're in a bash-in-bash case, so assume bash with SHLVL less than
      # 2 (bash, or bash-in-zsh/bash) always needs to be incremented by 1.
      ''
      [ "$SHLVL" -gt 2 ] || SHLVL=$((SHLVL + 1))
      ''

      # home-manager puts sessionVariables in a file only sourced during login.
      # fix it so we can actually verify changes by opening a new terminal rather than relogging in.
      ''
      unset __HM_SESS_VARS_SOURCED
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      ''

      # this MUST come after all git aliases
      #''
      ###############################################################
      ## git-completion.sh
      ###############################################################
      #${builtins.readFile snippets/git-completion.sh}
      ###############################################################
      ## End git-completion.sh
      ###############################################################
      #''

      # this MUST be last so all aliases are defined
      ''
      ##############################################################
      # alias_completion.bash
      ##############################################################
      ${builtins.readFile snippets/alias_completion.bash}
      ##############################################################
      # End alias_completion.bash
      ##############################################################
      ''
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableVteIntegration = true;
    autocd = false;
    defaultKeymap = "emacs";

    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = false;
      save = 100000;
      size = 100000;
      share = true;
    };
    historySubstringSearch = {
      enable = true;
      # hitting up or down will use the currently typed string in the back into history
    };

    # using prezto syntax highlighting instead
    #syntaxHighlighting = {
    #  enable = true;
    #  styles = "";
    #};

    # instead of a plugin manager, use the plugins directly in nix recipes.
    # see examples: https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.plugins
    plugins = [
      {
        # Adds the 'up' command

        # will source up.plugin.zsh
        name = "up";
        src = pkgs.fetchFromGitHub {
          owner = "peterhurford";
          repo = "up.zsh";
          # latest commit as of 2023-08-01, already 7+ years old
          rev = "c8cc0d0edd6be2d01f467267e3ed385c386a0acb";
          # use this to generate an error that shows the real value
          #  sha256 = lib.fakeSha256;
          sha256 = "sha256-yUWmKi95l7UFcjk/9Cfy/dDXQD3K/m2Q+q72YLZvZak=";
        };
      }
    ];

    prezto = {
      enable = true;
      # fish-like autosuggestions
      # Set the color for the found portion (implies it's enabled)
      autosuggestions.color = "fg=6";
      # Set case-sensitivity for completion, history lookup, etc.
      caseSensitive = true;
      # color output
      color = true;

      editor = {
        # Do NOT use dotExpansion.  It conflicts with git needing to use .. vs ... when diffing.
        ## Auto convert .... to ../..
        #dotExpansion = true;
        keymap = "emacs";
        # Allow the zsh prompt context to be shown.  Really only relevant to VI
        promptContext = true;
      };

      # prezto modules.  Order matters.
      #  'autosuggestions' must be after 'syntax-highlighting'
      #  'autosuggestions' must be after 'history-substring-search'
      #  'completion' must be after 'utility'
      #  'environment' must be loaded first
      #  'syntax-highlighting' must be second to last, right before 'prompt'
      #    unless 'history-substring-search' is also used, then right before
      #    it as well.
      #  'fasd' must be after 'completion'
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "spectrum"
        "utility"
        "completion"
        "git"
        "python"
        "screen"
        "syntax-highlighting"
        "autosuggestions"
        # using starship instead
        #"prompt"
      ];

      # pmodule configurations

      # Using starship instead, which means prezto prompt has to be disabled
      #prompt = {
      #  theme = "starship";
      #  # set the pwd type to 'short', 'long' (no ~ expansion), or 'full' (~ expansion)
      #  pwdLength = "long";
      #  # don't show return values in the prompt
      #  showReturnVal = false;
      #};

      python = {
        # Auto switch the Python virtualenv on directory change.
        virtualenvAutoSwitch = true;
        # Automatically initialize virtualenvwrapper if pre-requisites are met.
        virtualenvInitialize = true;
      };

      syntaxHighlighting = {
        highlighters = [
          "main"
          "brackets"
          "pattern"
          "line"
          "root"
          # do NOT include 'cursor' here.  It makes block cursors disappear when moving over text
          #"cursor"
        ];

        # special command-patterns to highlight
        pattern = {
          "rm*-rf*" = "fg=white,bold,bg=red";
        };
      };

      terminal = {
        # Auto set the tab and window titles.
        autoTitle = true;
        # Set the window title format.
        windowTitleFormat = "%n@%m: %s";
        # Set the tab title format.
        tabTitleFormat = "%m: %s";
        # Set the terminal multiplexer title format.
        multiplexerTitleFormat = "%s";
      };

      # Enabled safe options? This aliases cp, ln, mv and rm so that they prompt
      # before deleting or overwriting files. Set to 'no' to disable this safer
      # behavior.
      utility.safeOps = false;
    };


    initExtraBeforeCompInit = ''
      zstyle ':completion:*' completer _list _expand _complete _ignored _match
      zstyle ':completion:*' completions 1
      zstyle ':completion:*' insert-unambiguous true
      zstyle ':completion:*' preserve-prefix '//[^/]##/'
      zstyle ':completion:*' use-cache yes
    '';

    # this gets disregarded when prezto is enabled because prezto already includes loading compinit.
    completionInit = lib.concatLines [
      # allow more advanced completion functionality
      "autoload -U +X -z compinit && compinit"
      # allow bash-style completion to be parsed as well
      "autoload -U +X bashcompinit && bashcompinit"
    ];

    initExtraFirst = lib.concatLines [
      ''
      ####################################################
      # Start initExtraFirst
      ####################################################
      ''

      # these don't have home-manager options to enable
      "setopt nomatch notify complete_aliases listambiguous pushdignoredups noautomenu nomenucomplete histsavenodups histverify noflowcontrol"

      # the completionInit gets ignored when prezto is enabled because it's trying to be efficient and not call it twice.
      # but we customized it, so we have to add it manually
      "autoload -U +X -z compinit && compinit"
      # Need to enable the bash completion options very early so the functions are defined when sourcing completion scripts in the initExtra
      # allow bash-style completion to be parsed as well
      "autoload -U +X bashcompinit && bashcompinit"

      ''
      ####################################################
      # End initExtraFirst
      ####################################################
      ''
    ];

    initExtra = lib.concatLines [
      ''
      # home-manager puts sessionVariables in a file only sourced during login.
      # fix it so we can actually verify changes by opening a new terminal rather than relogging in.
      unset __HM_SESS_VARS_SOURCED
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      ''

      ''
      ##############################################################
      # Start custom keymap
      ##############################################################
      ''

      # mark tracking functions so we can properly handle
      # Ctrl+g as unset mark if the mark is set
      ''
      unset-mark-command () {
          zle set-mark-command -n -1
          MARKISSET=false
      }
      zle -N unset-mark-command
      ''

      ''
      copy-region-as-kill-unmark () {
          zle copy-region-as-kill
          # also unset mark like it should
          zle unset-mark-command
          MARKISSET=false
      }
      zle -N copy-region-as-kill-unmark
      ''

      ''
      kill-region-tracked () {
          zle kill-region
          MARKISSET=false
      }
      zle -N kill-region-tracked
      ''

      ''
      set-mark-command-tracked () {
          zle set-mark-command
          MARKISSET=true
      }
      zle -N set-mark-command-tracked
      ''

      # uses MARKISSET from other commands
      ''
      unset-or-break-mark-command () {
          if $${MARKISSET} >/dev/null
          then
              zle unset-mark-command
          else
              zle send-break
          fi
      }
      zle -N unset-or-break-mark-command
      ''

      # define functions to share clipboard with X11
      # breaks yank-pop

      # uses CUTBUFFER from x-yank
      ''
      x-backward-kill-word () {
        zle backward-kill-word
        print -rn $${CUTBUFFER} | xsel -i
      }
      zle -N x-backward-kill-word
      ''

      # uses CUTBUFFER from x-yank
      ''
      x-copy-region-as-kill () {
        zle copy-region-as-kill
        print -rn $${CUTBUFFER} | xsel -i
      }
      zle -N x-copy-region-as-kill
      ''

      # uses CUTBUFFER from x-yank
      ''
      x-kill-region () {
        zle kill-region
        print -rn $${CUTBUFFER} | xsel -i
      }
      zle -N x-kill-region
      ''

      ''
      x-yank () {
        CUTBUFFER=$(xsel -o </dev/null)
        zle yank
      }
      zle -N x-yank
      ''

      # uses CUTBUFFER from x-yank
      ''
      x-kill-line () {
        zle kill-line
        print -rn $${CUTBUFFER} | xsel -i
      }
      zle -N x-kill-line
      ''


      # Alt+u
      ''bindkey '^[u' beginning-of-line''

      # Alt+o
      ''bindkey '^[o' end-of-line''
      
      # Alt+l
      ''bindkey '^[l' forward-char''

      # Alt+Shift+l
      ''bindkey '^[L' emacs-forward-word''

      # Alt+l
      ''bindkey '^[j' backward-char''

      # Alt+Shift+j
      ''bindkey '^[J' emacs-backward-word''

      # Ctrl+Backspace
      ''bindkey '^^?' backward-kill-word''

      # Ctrl+w
      ''bindkey '^w' kill-region-tracked''

      # Alt+w
      ''bindkey '^[w' copy-region-as-kill-unmark''

      # Ctrl+k
      ''bindkey '^k' kill-line''

      # Ctrl+y
      ''bindkey '^y' yank''

      # Alt+y
      ''bindkey '^[y' yank-pop''

      # Alt+space
      ''bindkey '^[ ' set-mark-command-tracked''

      # Ctrl+space
      ''bindkey '^ ' set-mark-command-tracked''

      # Ctrl+@ (what's actually sent on Ctrl+space)
      ''bindkey '^@' set-mark-command-tracked''

      # Ctrl+Shift+-
      ''bindkey '^_' undo''

      # Ctrl+x Ctrl+x
      ''bindkey '^x^x' exchange-point-and-mark''

      # Ctrl+g
      ''bindkey '^g' unset-or-break-mark-command''

      ''
      ##############################################################
      # End custom keymap
      ##############################################################
      ''
    ];
  };
}

# vim: sw=2:expandtab

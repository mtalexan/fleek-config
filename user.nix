{ pkgs, misc, lib, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  programs.bat = {
    enable = true;
    theme = "TwoDark";
    map-syntax = [
      "*.jenkinsfile:Groovy"
      "*.props:Java Properties"
      "*.incl:Bash"
    ];
  };

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.exa = {
    enable = true;
    enableAliases = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  programs.fzf = {
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultOptions = [
      #"--layout=default"
      # ergo-key bindings using alt
      "--bind='alt-bs:backward-kill-word,alt-j:backward-char,alt-l:forward-char,alt-i:up,alt-k:down,ctrl-j:backward-word,ctrl-l:forward-word,ctrl-i:page-up,ctrl-k:page-down,ctrl-g:cancel,alt-u:beginning-of-line,alt-o:end-of-line,ctrl-n:next-history,ctrl-p:previous-history,ctrl-]:jump,alt-space:toggle-in,ctrl-space:toggle-in'"
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
  };

  programs.neovim = {
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
      set nobackup
      set relativenumber
    '';
  };

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
        threshold = 2;
        repeat = true; # repeat symbol for the number of levels
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
        pipestatus_format = "(\[$pipestatus\]=>[$symbol $signal_name$common_meaning$maybe_int]($style))";
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
        format = "[ @$hash( \($tag\))]($style) ";
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
        format = "[$state(\($progress_current/$progress_total\))]($style)";
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
        format = "[$symbol($profile)( \($region\))( \[$duration\])]($style) ";
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
        format = "([\[$name\]]($style)) ";
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
        format = "[$symbol($version( \(OTP $otp_version\)))]($style) ";
        disabled = true;
      };

      fossil_branch = {
        style = "git_commitish";
        format = "([$symbol$branch]($style) )";
        disabled = false;
      };

      gcloud = {
        format = "([$symbol$account(@$domain)(\($region\))]($style)) ";
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
        format = "[$symbol$context(\($namespace\))]($style) ";
        disabled = true;
      };

      meson = {
        format = "[$symbol$project]($style) ";
        disabled = false;
      };

      nix_shell = {
        format = "[$symbol$state( \($name\))]($style) ";
        heuristic = true; # try to detect "nix shell" style shells too
        disabled = false;
      };

      ocaml = {
        format = "[$symbol($version)( \($switch_indicator$switch_name\))]($style) ";
        disabled = false;
      };

      openstack = {
        format = "[$symbol$cloud(\($project\))]($style) ";
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
        format = "([$symbol\[$env\]]($style) )";
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

  # shared shell settings
  home = {
    sessionVariables = {
      GCC_COLORS = "error=01;31;warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
      SUDOEDITOR = "nvim";
      GIT_EDITOR = "nvim";
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
    initExtra = ''
      # home-manager annoyingly puts sessionVariables in a file only sourced by .bash_profile.
      # fix it so we can actually verify changes by opening a new terminal rather than relogging in
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

      ##############################################################
      # Must come after any git aliases
      ${builtins.readFile snippets/git-completion.sh}
      ##############################################################
      ##############################################################
      # this MUST be last so all aliases are defined
      ${builtins.readFile snippets/alias_completion.bash}
      ##############################################################
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    initExtra = ''
      # home-manager annoyingly puts sessionVariables in a file only sourced by .bash_profile.
      # fix it so we can actually verify changes by opening a new terminal rather than relogging in
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

      ##############################################################
      # put it last so all git aliases are defined
      ${builtins.readFile snippets/git-completion.sh}
      ##############################################################
    '';
  };
}

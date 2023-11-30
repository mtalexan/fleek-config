{ pkgs, misc, lib, ... }: {
  # Settings for the different shells go in here

  # shared shell settings
  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
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

  programs.bash = {
    enable = true;
    # This doesn't seem to work.  The line had to be added manually instead
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

    # this is included in all shell types, not just interactive
    bashrcExtra = lib.concatLines [
      # enableCompletion = true is supposed to set this, but it doesn't seem to work.  Add it manually
      ''
        . ${pkgs.bash-completion}/share/bash-completion/bash_completion
      ''
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
      ${builtins.readFile ../snippets/alias_completion.bash}
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
      # conflicts with tmux copy-mode set mark
      #''bindkey '^ ' set-mark-command-tracked''

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
    ]; # end programs.zsh.initExtras = lib.concatLines
  }; # end programs.zsh
}

# vim: sw=2:expandtab
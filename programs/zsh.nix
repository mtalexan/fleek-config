{ pkgs, misc, lib, ... }: {
  # Included by modules/shells.nix
  
  # ZSH plugins added separately as packages
  home.packages = [
    pkgs.zsh-autosuggestions
    pkgs.zsh-completions
    pkgs.zsh-fast-syntax-highlighting
    pkgs.zsh-fzf-tab
    # Nix integration
    pkgs.nix-zsh-completions
    # provides notify-send that we need for long task completion notification
    pkgs.libnotify
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion =  {
      enable = true;
      # pink foreground for completion, with underline
      highlight = "fg=#ff00ff,bg=underline";
      # strategy = [ "history" ]; #default
    };
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

    # The fast-syntax-highlighting and F-Sy-H plugins are both buggy and don't define their functions properly.
    # Use the actual working default one.
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        # from the list https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
        "brackets"
        #"cursor"
      ];
      # overrides for default colors
      #styles = {};
    };

    # instead of a plugin manager, use the plugins directly in nix recipes.
    # see examples: https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.plugins
    plugins = [
      {# MUST BE FIRST

        # replaces zsh default completion menu prompt with an fzf one

        # will source fzf-tab.plugin.zsh
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          # latest master as of 2024-01-26
          rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
          sha256 = "sha256-gvZp8P3quOtcy1Xtt1LAW1cfZ/zCtnAmnWqcwrKel6w=";
          #sha256 = lib.fakeSha256;
        };
      }
      {
        # will source zsh-autosuggestions.plugin.zsh
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
          #sha256 = lib.fakeSha256;
        };
      }
      {
        # sets bell w/ message when long running things complete

        # will source auto-notify.plugin.zsh
        name = "auto-notify";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-auto-notify";
          rev = "0.10.1";
          sha256 = "sha256-l5nXzCC7MT3hxRQPZv1RFalXZm7uKABZtfEZSMdVmro=";
          #sha256 = lib.fakeSha256;
        };
      }
      # conflicts with Ctrl+left/right for fwd/back word, and selection doesn't work with kitty
      #{
      #  # keybindings for shift selection in CLI
      #
      #  # WARNING: kitty can conflict with some of these.
      #
      #  # will source zsh-shift-select.plugin.zsh
      #  name = "zsh-shift-select";
      #  src = pkgs.fetchFromGitHub {
      #    owner = "jirutka";
      #    repo = "zsh-shift-select";
      #    rev = "v0.1.1";
      #    sha256 = "sha256-4kUUBH2GTMb/d6PUNiSNFogkvDUSwMX823j4xsroJKs=";
      #    #sha256 = lib.fakeSha256;
      #  };
      #}
      {
        # Adds the 'up' command

        # will source up.plugin.zsh
        name = "up";
        src = pkgs.fetchFromGitHub {
          owner = "peterhurford";
          repo = "up.zsh";
          # latest commit as of 2023-08-01, already 7+ years old
          rev = "c8cc0d0edd6be2d01f467267e3ed385c386a0acb";
          sha256 = "sha256-yUWmKi95l7UFcjk/9Cfy/dDXQD3K/m2Q+q72YLZvZak=";
          #sha256 = lib.fakeSha256;
        };
      }
    ];

    # prezto only works if we use it for the prompt.
    # we're using starship instead
    #prezto = {
    #  enable = true;
    #  # fish-like autosuggestions
    #  # Set the color for the found portion (implies it's enabled)
    #  autosuggestions.color = "fg=bright-blue";
    #  # Set case-sensitivity for completion, history lookup, etc.
    #  caseSensitive = true;
    #  # color output
    #  color = true;
    #
    #  editor = {
    #    # Do NOT use dotExpansion.  It conflicts with git needing to use .. vs ... when diffing.
    #    ## Auto convert .... to ../..
    #    #dotExpansion = true;
    #    keymap = "emacs";
    #    # Allow the zsh prompt context to be shown.  Really only relevant to VI
    #    promptContext = true;
    #  };
    #
    #  # prezto modules.  Order matters.
    #  #  'autosuggestions' must be after 'syntax-highlighting'
    #  #  'autosuggestions' must be after 'history-substring-search'
    #  #  'completion' must be after 'utility'
    #  #  'environment' must be loaded first
    #  #  'syntax-highlighting' must be second to last, right before 'prompt'
    #  #    unless 'history-substring-search' is also used, then right before
    #  #    it as well.
    #  #  'fasd' must be after 'completion'
    #  pmodules = [
    #    "environment"
    #    "terminal"
    #    "editor"
    #    "history"
    #    "spectrum"
    #    "utility"
    #    "completion"
    #    "git"
    #    "python"
    #    "screen"
    #    "syntax-highlighting"
    #    "autosuggestions"
    #    "prompt"
    #  ];
    #
    #  # pmodule configurations
    #
    #  prompt = {
    #    theme = "starship";
    #    # set the pwd type to 'short', 'long' (no ~ expansion), or 'full' (~ expansion)
    #    pwdLength = "long";
    #    # don't show return values in the prompt
    #    showReturnVal = false;
    #  };
    #
    #  python = {
    #    # Auto switch the Python virtualenv on directory change.
    #    virtualenvAutoSwitch = true;
    #    # Automatically initialize virtualenvwrapper if pre-requisites are met.
    #    virtualenvInitialize = true;
    #  };
    #
    #  syntaxHighlighting = {
    #    highlighters = [
    #      "main"
    #      "brackets"
    #      "pattern"
    #      "line"
    #      "root"
    #      # do NOT include 'cursor' here.  It makes block cursors disappear when moving over text
    #      #"cursor"
    #    ];
    #
    #    # special command-patterns to highlight
    #    pattern = {
    #      "rm*-rf*" = "fg=white,bold,bg=red";
    #    };
    #  };
    #
    #  terminal = {
    #    # Auto set the tab and window titles.
    #    autoTitle = true;
    #    # Set the window title format.
    #    windowTitleFormat = "%n@%m: %s";
    #    # Set the tab title format.
    #    tabTitleFormat = "%m: %s";
    #    # Set the terminal multiplexer title format.
    #    multiplexerTitleFormat = "%s";
    #  };
    #
    #  # Enabled safe options? This aliases cp, ln, mv and rm so that they prompt
    #  # before deleting or overwriting files. Set to 'no' to disable this safer
    #  # behavior.
    #  utility.safeOps = false;
    #};

    # loaded for ALL session types, env variables exclusive to zsh
    envExtra = lib.concatLines [
      # make sure our SHELL is set to zsh so it's used by default.
      ''SHELL=$(command -v zsh)''
    ];

    initExtraBeforeCompInit = ''
      # See man zshcompsys for details on completers and their options

      # Ordered list of completion engines to try. 
      # Do NOT use _expand which does partial expansion.
      # _approximate lists possible corrections only if nothing else matches
      # _manuals adds manpage completion
      # _complete is the standard completion function where functions are installed/defined explicitly
      # _ignored re-adds results from other completers that were removed by 'ignore-patterns' option
      # _list waits on results and calls completion a second time without modifying the current word/line. This ensures the _match and _approximate results actually
      #       only get used if nothing else matches.
      # _match Treats the original as a glob match pattern against possible completion candidates.
      # _prefix ignores any suffix after the cursor and tries again. Can set a different list of completers to use when trying again.
      #         Usually needs COMPLETE_IN_WORD set to be useful.
      # WARNING: _expand, _expand_alias, and _correct are intended for point-expansion/replacement and not for real use here
      zstyle ':completion:*' completer _list _complete _ignored _manuals _approximate
      # expand unambiguous prefixes from any/all completers
      zstyle ':completion:*' expand _prefix
      # highlight the first ambiguous character in the match. If set 'yes' the default is used, otherwise a color or style may be
      zstyle ':completion:*' show-ambiguity yes

      # set the style to use when _approximate offers corrections
      zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
      # warnings and messages format from the completion engine
      zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
      zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
      
      # bring up a selection menu to pick the completion if the list is long.
      # if selecting one isn't supported by the completion engine, just bring up the menu for scrolling instead.
      # 'interactive' means the search pattern can be interactively adjusted in real time to update the results 
      # in the list rather than needing a keypress to do it first.
      # TODO: Investigate fzf-tab instead
      zstyle ':completion:*' menu select=long-list interactive

      # cache results so the same thing again is faster
      zstyle ':completion:*' use-cache yes

      # _match

      # Insert prefixes that are shared by all possible matches.
      zstyle ':completion:*:match:*' insert-unambiguous true

      # _ignored

      # if there's only 1 match from the _ignored completer, show it with the original but don't insert it
      zstyle ':completion:*:ignored:*' single-ignored show

      # _expand

      # disable expansion of nested subshell commands into their resulting values when using the _expand completer
      zstyle ':completion:*:expand:*' substitute no

      # _manuals

      # when completing man pages, set the specific page (e.g. 'man 5') using the suffix syntax (e.g. 'man <cmd>.5') so it can be easily changed if there's multiple section matches
      # alternative: insert the 'man 5 ' as a prefix when that's the only match
      zstyle ':completion:*:manuals.*' insert-sections suffix

      # _approximate
      # The name of the completer is set to approximate-N where N is the number of corrections, but just 'approximate' applies to all of them

      # limit the number of corrections allowed. It iterates thru the number of possible corrections, and stops if any matches are found, this sets the upper bound.
      zstyle ':completion:*:approximate:*' max-errors 4
      # Insert prefixes that are shared by all possible matches.
      zstyle ':completion:*:approximate:*' insert-unambiguous true
      # Always show the unmodified original as an option, even if there's only 1 unambiguous match. Without this set, 
      # the original is already an option, but only if there's no single unambiguous match.
      zstyle ':completion:*:approximate:*' original yes
      # add descriptions to the grouping of approximate matches in green
      #zstyle ':completion:*:approximate:*:*:*:descriptions' format '%F{green}-- $d --%f'

      # Completion settings for specific applicatons

      zstyle ':completion:*:*:kill:*' verbose yes
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
      # 'completealiases' makes the aliases themselves separate completions not based on the commands they alias. Don't set it
      "setopt nomatch notify listambiguous pushdignoredups noautomenu nomenucomplete histsavenodups histverify noflowcontrol"

      # create a cache folder for zsh
      "mkdir -p ~/.cache/zsh"

      # the completionInit gets ignored when prezto is enabled because it's trying to be efficient and not call it twice.
      # but we customized it, so we have to add it manually.
      # Make sure to specify a location to write the compdump so it can be cached instead of regeenrated on each load
      "autoload -U +X -z compinit && compinit -d ~/.cache/zsh/zcompdump"
      # Need to enable the bash completion options very early so the functions are defined when sourcing completion scripts in the initExtra
      # allow bash-style completion to be parsed as well
      # Make sure to specify a location to write the compdump so it can be cached instead of regeenrated on each load
      "autoload -U +X bashcompinit && bashcompinit -d ~/.cache/zsh/zbashcompdump"

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
      # Auto notify plugin settings
      ##############################################################

      # only notify if it took longer than 10 seconds (default=10)
      AUTO_NOTIFY_THRESHOLD=30
      # make the notifications expire after 10 seconds (default=8)
      AUTO_NOTIFY_EXPIRE_TIME=10000
      # extra commands to ignore (see variable for defaults)
      AUTO_NOTIFY_IGNORE+=("bat" "code" "kitty")
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

      # To figure out what the keybinding is, press Ctrl+v and then the key combo you're interested in.
      # That will print shell key code you need to provide to bindkey.

      # Alt+u
      ''bindkey '^[u' beginning-of-line''
      # Home
      ''bindkey '\e[H' beginning-of-line''
      ''bindkey '\eOH' beginning-of-line''

      # Alt+o
      ''bindkey '^[o' end-of-line''
      # End
      ''bindkey '\e[F' end-of-line''
      ''bindkey '\eOF' end-of-line''

      # Alt+l
      ''bindkey '^[l' forward-char''
      # Right
      ''bindkey '\e[C' forward-char''
      ''bindkey '\eOC' forward-char''

      # Alt+Shift+l
      ''bindkey '^[L' emacs-forward-word''
      # Ctrl+Right
      ''bindkey '^[[1;5C' emacs-forward-word''
      ''bindkey '\e[1;5C' emacs-forward-word''

      # Alt+l
      ''bindkey '^[j' backward-char''
      # Left
      ''bindkey '\e[D' backward-char''
      ''bindkey '\eOD' backward-char''

      # Alt+Shift+j
      ''bindkey '^[J' emacs-backward-word''
      # Ctrl+Left
      ''bindkey '^[[1;5D' emacs-backward-word''
      ''bindkey '\e[1;5D' emacs-backward-word''

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

# vim: ts=2:sw=2:expandtab

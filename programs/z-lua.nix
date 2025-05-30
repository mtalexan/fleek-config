{ pkgs, misc, lib, ... }: {
  # NOT USED: doesn't work
  #
  # An older alternative to zoxide.
  # 'z' commands for directory jumps based on frecency.  
  # 'z' for jump down dirs, 'zb' for jump up dirs, 'zf' for fzf prompt, 'zi' for non-FZF interactive,
  # and 'zbi'/'zbf' for jump up w/ interactive.
  #
  # Differences with zoxide:
  #   Supports direct lua regex syntax
  #   Default to only looking in subdirectories rather than needing a trailing '/' for that behavior.
  #   Slower at lookups since its' lua instead of compiled Rust
  #   Includes more CLI flags for different behaviors.
  #   Zoxide adds time based frecency ranking vs only changes per-access regardless of delays between
  #   zf (z -I) command is only interactive with multiple matches, while zi (zoxide equivalent) always is
  #   Specialized jump upwards/backwards syntax with 2-arg syntax that does swap of one word for another to find peer folders,
  #    and 0-arg format to jump to git root
  #   Note: Zoxide search format is almost the same as z.lua enhanced syntax
  programs.z-lua = {
    enable = true;
    # we want to customize, don't just take defaults
    enableAliases = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
    # options to pass to the 'zoxide init' command
    options = [
      # better search syntax: 
      #   - only match folder if lowest subfolder matches last term
      #   - skip current directory match and keep looking
      #   - skip non-existent/missing match and keep looking
      "enhanced"
      # Only update freceny rank on dir change, not if prompt is redrawn
      "once"
      # print the directory being jumped to (always avaiable with '-e' added)
      #"echo"
      # use fzf for interactive completion (i.e. 'zf')
      "fzf"
    ];
    # The following environment variables have to be set manually in the home.sessionVariables if needed
    # _ZL_CMD the command to run to invoke the tool, default="z"
    # _ZL_DATA the location to store the datafile, default=~/.zlua
    # _ZL_NO_PROMPT_COMMAND if you're setting the PROMPT_COMMAND directly, set this
    # _ZL_EXCLUDE_DIRS comma-separated list of dirs to exclude
    # _ZL_ADD_ONCE = 1 to update database only on $PWD change instead of increasing frecency when the prompt is re-shown.
    #                  also can be set with the options = "once" above.
    # _ZL_MAXAGE after the sum of all entry ranks hits this limit, it cuts all ranks by 10% and drops anything below 1
    # _ZL_CD replace the 'cd' command it uses to change the directory, default='builtin cd'
    # _ZL_ECHO = 1 to print the name of the new directory it's changing to. Useful for scripting, but can 
    #            be set with a CLI option too.
    # _ZL_MATCH_MODE = 1 to enable 'enhanced' mode. CAn also be set with options = "enhanced" above.
    # _ZL_NO_CHECK = 1 to disable path validation.
    # _ZL_HYPHEN = 0 to treat '-' as a special lua regex character. 1 to treat as regular char. Blank or 'auto', 
    #              try lua regexp first, then fall back to regular char.
    # _ZL_ROOT_MARKERS comma separated list of files/folders to use as "root" markers (e.g. '.git') when using 0-arg 'zb' command.
    #                  default="".git,.svn,.hg,.root,package.json"
    # _ZL_CLINK_PROMPT_PRIORITY default=99 (clink is a Windows cmd.exe tool)
    # _ZL_FZF_FLAG override default FZF flags. default = '+s -e' (no sort, space separated keywords)
    #               Warning: this is only part of the command-line it supplies to FZF.  A custom function is necessary if
    #                        you want to completely override it
    # _ZL_INT_SORT = 1 to sort interactive/fzf results alphabetically instead of by rank
    # _ZL_FZF_HEIGHT set just --height argument to FZF
  };

  # shared shell settings
  # WARNING: by default all sessionVariables are only sourced once at login.
  #   Special logic is added to the bash and zsh initExtra to force re-sourcing on each new terminal 
  home.sessionVariables = {
    _ZL_FZF_HEIGHT = "50%";
    ## use options like FZF changeDir (Alt+C) display options
    #_ZL_FZF_FLAG = lib.concatStringsSep " " [
    #  "--preview 'eza --tree -L2 --color=always {}'"
    #  "--preview-window right,border-vertical"
    #  "--bind 'ctrl-/:toggle-preview'"
    #  "--scheme=path"
    #  "--filepath-word"
    #  "--multi"
    #  "--info=inline"
    #  "--border=sharp"
    #  # let it be taller than fzf history, but not fullscreen like changeDir
    #  "--height=50%"
    #  "--tabstop=4"
    #  "--color=dark"
    #  "--cycle"
    #  "--layout=reverse"
    #  # no sorting (use provided order that's based on frecency)
    #  "+s"
    #  # space separated independent search terms
    #  "-e"
    #];
  };
  home.shellAliases = {
    # the base function provided is z(), so we need to explicitly use that defined function
    # in these aliases

    # sub-directory moves/searches work better with the built-in FZF directory search

    ## do sub-dir relative searches
    #z = "command z -c";
    ## sub-dir relative fzf searches
    #zf = "zf_custom -c";
    #zi = "zf_custom -c";

    # do upward search. w/ 0-args it goes to git root, 1-arg it looks for upward match, 2-args it does match subst
    # Note: 'z -b' doesn't work, we have to force it with -l or -e and then manually move.
    zb = "zb_go_custom";
    # the interactive version of upward search
    # Note: 'z -b -I' doesn't work, we have to force it with -l or -e and then manually move)
    zbi = "zf_custom -b";
    zbf = "zf_custom -b";
  };

  programs.bash.initExtra = lib.concatLines [
    # the default function for zf, we have to customize it if we want custom FZF functionality
    #''
    #function zf() {
    #  local $dir="$(z -l "$@" | fzf --nth 2.. --reverse --inline-info --tac +s -e --height 35%)"
    #  [ -n "$dir" ] && cd "$(echo $dri | sed -e s@^\s*\S*\s*@@')"
    #}
    #''

    # the 'z -b' and 'z -b -I' commands don't actually change directories (bug) or prompt, so wrap them with a custom script
    ''
    function zb_go_custom() {
      local $dir="$(z -e -b "$@")"
      [ -n "$dir" ] && cd "$dir"
    }
    ''

    # the default function for zf, we have to customize it if we want custom FZF functionality
    ''
    function zf_custom() {
      local $dir="$(z -l "$@" | fzf --nth 2.. --reverse --inline-info --tac +s -e \
              --height 50% \
    ''
    # 'z -I' always passes the score then the folder name with some leading indentation.
    # Carefully echo the string, parse it thru awk to get only the second column, and then use
    # the result in an eza --tree command that shows colors and only 2 dirs deep in each tree
    ''
              --preview "eza --tree -L2 --color=always \$( echo {} | sed -e 's@^\S*\s*@@')" \
              --preview-window right,border-vertical \
              --bind 'ctrl-/:toggle-preview' \
              --scheme=path \
              --filepath-word \
              --multi \
              --border=sharp \
              --tabstop=4 \
              --color=dark \
              --cycle)"
      # make sure to strip the ranking score and spaces off the front
      [ -n "$dir" ] && cd "$(echo "$dir" | sed -e 's@^\s*\S*\s*@@')"
    }
    ''
  ];

  # default priority, formerly initExtra
  programs.zsh.initContent = lib.mkMerge [ (lib.mkOrder 1000 (lib.concatLines [
    # the default function for zf, we have to customize it if we want custom FZF functionality
    #''
    #function zf() {
    #  local $dir="$(z -l "$@" | fzf --nth 2.. --reverse --inline-info --tac +s -e --height 35%)"
    #  [ -n "$dir" ] && cd "$(echo $dri | sed -e s@^\s\S*\s*@@')"
    #}
    #''

    # the 'z -b' command without any other arguments doesn't actually change directories (bug), so wrap it with a custom script
    ''
    function zb_go_custom() {
      local $dir="$(z -e -b "$@")"
      [ -n "$dir" ] && cd "$dir"
    }
    ''

    # the default function for zf, we have to customize it if we want custom FZF functionality
    ''
    function zf_custom() {
      local $dir="$(z -l "$@" | fzf --nth 2.. --reverse --inline-info --tac +s -e \
              --height 50% \
    ''
    # 'z -I' always passes the score then the folder name with some leading indentation.
    # Carefully echo the string, parse it thru awk to get only the second column, and then use
    # the result in an eza --tree command that shows colors and only 2 dirs deep in each tree
    ''
              --preview "eza --tree -L2 --color=always \$( echo {} | sed -e 's@^\S*\s*@@')" \
              --preview-window right,border-vertical \
              --bind 'ctrl-/:toggle-preview' \
              --scheme=path \
              --filepath-word \
              --multi \
              --border=sharp \
              --tabstop=4 \
              --color=dark \
              --cycle)"
      # make sure to strip the ranking score and spaces off the front
      [ -n "$dir" ] && cd "$(echo "$dir" | sed -e 's@^\s*\S*\s*@@')"
    }
    ''
  ]))];
}

# vim: ts=2:sw=2:expandtab

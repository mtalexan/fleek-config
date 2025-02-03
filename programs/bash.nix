{ pkgs, misc, lib, ... }: {
  # Extra packages needed for Bash Integration
  home.packages = [
    pkgs.bashInteractive
    pkgs.bash-completion
    # Nix integration
    pkgs.nix-bash-completions
  ];

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
}

# vim: ts=2:sw=2:expandtab

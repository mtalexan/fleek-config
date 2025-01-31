{ pkgs, misc, lib, ... }: {
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
}

# vim: ts=2:sw=2:expandtab

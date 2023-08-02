{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
   home.shellAliases = {
    "bathelp" = "bat --plain --language=help";
    
    "batpretty" = "prettybat";
    
    "cat" = "bat";
    
    "catp" = "bat -P";
    
    "fleeks" = "cd ~/.local/share/fleek";
    
    "gbvv" = "git branch -vv";
    
    "gcm" = "git commit";
    
    "gd" = "git diff";
    
    "gdc" = "git diff --cached";
    
    "glg" = "git log --oneline --decorate --graph";
    
    "la" = "exa -a";
    
    "ll" = "exa -l";
    
    "lla" = "exa -l -a";
    
    "llag" = "exa -l -a --git";
    
    "llg" = "exa -l --git";
    
    "ls" = "exa";
    
    "lt" = "exa --tree";
    
    "tree" = "exa --tree";
    };
}

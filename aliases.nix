{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
   home.shellAliases = {
    "cat" = "bat";
    
    "catp" = "bat -P";
    
    "fleeks" = "cd ~/.local/share/fleek";
    
    "g" = "git";
    
    "gbvv" = "git branch -vv";
    
    "gcm" = "git commit";
    
    "gd" = "git diff";
    
    "gdc" = "git diff --cached";
    
    "glg" = "git log --oneline --decorate --graph";
    
    "gs" = "git status";
    };
}

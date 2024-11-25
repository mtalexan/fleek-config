{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
   home.shellAliases = {
    "bathelp" = "bat --plain --language=help";
    
    "batpretty" = "prettybat";
    
    "cat" = "bat";
    
    "catp" = "bat -P";
    
    "fleek-apply" = "NIXPKGS_ALLOW_UNFREE=1 nix run --no-wrtie-lock-file --impure home-manager/master -- -b bak switch --flake ".#$(id -un)@$(hostname)" ";
    
    "fleek-impure" = "fleek-apply --impure ";
    
    "fleeks" = "cd ~/.local/share/fleek";
    
    "gbc" = "git branch --show-current";
    
    "gbvv" = "git branch -vv";
    
    "gcm" = "git commit";
    
    "gd" = "git diff";
    
    "gdc" = "git diff --cached";
    
    "glg" = "git log --oneline --decorate --graph";
    
    "gs" = "git status";
    
    "la" = "eza -a";
    
    "latest-fleek-version" = "nix run https://getfleek.dev/latest.tar.gz -- version";
    
    "ll" = "eza -l";
    
    "lla" = "eza -l -a";
    
    "llag" = "eza -l -a --git";
    
    "llg" = "eza -l --git";
    
    "ls" = "eza";
    
    "lt" = "eza --tree";
    
    "rgfzf" = "sd rg-fzf";
    
    "tree" = "eza --tree";
    
    "update-fleek" = "nix run https://getfleek.dev/latest.tar.gz -- update";
    };
}

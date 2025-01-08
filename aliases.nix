{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
   home.shellAliases = {
    #"apply-WINDOWS-GAMING" = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@WINDOWS-GAMING";
    #"apply-bazzite" = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@bazzite";
    #"apply-cloud-t610" = "nix run --impure home-manager/master -- -b bak switch --flake .#mike@cloud-t610";
    #"apply-fedora" = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@fedora";
    #"apply-goln-422q533" = "nix run --impure home-manager/master -- -b bak switch --flake .#mtalexander@goln-422q533";
    #"apply-goln-5cl17g3" = "nix run --impure home-manager/master -- -b bak switch --flake .#mtalexander@goln-5cl17g3";
    #"apply-kubic-730xd" = "nix run --impure home-manager/master -- -b bak switch --flake .#mike@kubic-730xd";
    #"apply-laptop" = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@laptop";
    #"apply-laptopFedora" = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen2@laptopFedora";
    #"apply-vm-gol-422Q533" = "nix run --impure home-manager/master -- -b bak switch --flake .#dev@vm-gol-422Q533";
    
    "bathelp" = "bat --plain --language=help";
    
    "batpretty" = "prettybat";
    
    "cat" = "bat";
    
    "catp" = "bat -P";
    
    # runs a custom shell script named fleek-apply
    "fleek-impure" = "fleek-apply --impure";
    # Also see fleek-update, which is a directly callable script
    
    "fleeks" = "cd ~/.local/share/fleek";
    
    "gbc" = "git branch --show-current";
    
    "gbvv" = "git branch -vv";
    
    "gcm" = "git commit";
    
    "gd" = "git diff";
    
    "gdc" = "git diff --cached";
    
    "glg" = "git log --oneline --decorate --graph";
    
    "gs" = "git status";
    
    "la" = "eza -a";
    
    # Ejected from fleek
    #"latest-fleek-version" = "nix run https://getfleek.dev/latest.tar.gz -- version";
    
    "ll" = "eza -l";
    
    "lla" = "eza -l -a";
    
    "llag" = "eza -l -a --git";
    
    "llg" = "eza -l --git";
    
    "ls" = "eza";
    
    "lt" = "eza --tree";
    
    "rgfzf" = "sd rg-fzf";
    
    "tree" = "eza --tree";
    
    # Ejected from fleek
    #"update-fleek" = "nix run https://getfleek.dev/latest.tar.gz -- update";
    };
}

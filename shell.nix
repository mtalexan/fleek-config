{ pkgs, misc, ... }: {
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.# bash
  programs.bash.profileExtra = "[ -r ~/.nix-profile/etc/profile.d/nix.sh ] && source  ~/.nix-profile/etc/profile.d/nix.sh";
  programs.bash.initExtra = ''
    if [ -f /etc/bashrc ]; then
        . /etc/bashrc
    fi
    source <(fleek completion bash)
  '';
  programs.bash.enableCompletion = true;
  programs.bash.enableVteIntegration = true;
  programs.bash.enable = true;
}

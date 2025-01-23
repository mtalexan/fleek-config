{ pkgs, misc, ... }: {
  # The common git settings created by fleek for home-manager.
  programs.git = {
    enable = true;
    aliases = {
      pushall = "!git remote | xargs -L1 git push --all";
      graph = "log --decorate --oneline --graph";
      add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
    };

    extraConfig = {
      feature.manyFiles = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
    };

    lfs.enable = true;
    ignores = [ ".direnv" "result" ];

    # normally defined per-host, we want a single consistent default unless it's overridden on a host
    userName = "Mike";
    userEmail = "github@trackit.fe80.email";
  };
}

# vim:sw=2:expandtab
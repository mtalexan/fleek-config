{ pkgs, misc, lib, ... }: {
  home.packages = [
    pkgs.git
  ];

  # some per-system config is in the {system-name}/{username}.nix file also
  programs.git = {
    aliases = {
      unstage = "restore --staged";
      #added by default because it's so common
      #graph = "log --oneline --decorate --graph";
      co = "checkout";
      cm = "commit";
      bvv = "branch -vv";
      last = "log -1 HEAD";
      update = "pull --no-rebase --ff --no-commit --ff-only";
    };
    delta = {
      # automatically sets itself as the pager for git
      # and the interactive.diffFilter
      enable = true;
      options = {
        # these options have to be put under a separate feature name so they don't get applied
        # when using 'git add -i' or 'git add -p', that requires a specific text input format.
        decorations = {
          side-by-side = true;
          # files in listings need a box
          file-style = "bold yellow box";
        };
        features = "decorations";
        # themese are set to mirror bat automatically
        line-numbers = true;
        navigate = true;
        hyperlinks = true;
        # this causes it to open in vscode when hyperlinks to commits are clicked
        hyperlinks-file-link-format = "vscode://file/{path}:{line}" ;
        # use relative paths for all file names
        relative-paths = true;
        # tab display width
        tabs = 4;
        # header blocks only extend to the end of the file section and not the entire terminal width
        width = "variable";
      };
    };
    extraConfig = {
      diff = {
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };
      merge = {
        conflictStyle = "diff3";
      };
    };
    lfs = {
      enable = true;
    };
  };
}

# vim: sw=2:expandtab

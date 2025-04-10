{ pkgs, misc, lib, config, options, ... }: {

  imports = [
    # allow encrypting individual files in a repo using an SSH key-pair. See https://github.com/vlaci/git-agecrypt
    ./git-agecrypt.nix
  ];

   home.packages = [
    #automatically handled by programs.git.lfs.enable=true below
    #pkgs.git-lfs
  ];

  programs.git = {
    enable = true;

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
    lfs.enable = true;

    # maintenance isn't normally run on repos and usually has to be turned on manually per repo.
    # this automatically adds systemd timers for it and will run on any that are explicit registered
    # with 'git maintenance register' from within the repo
    maintenance.enable = true;

    signing = {
      # key gets set per identity/*.nix file
      format = "ssh";
      signByDefault = true;
    };

    extraConfig = {
      feature.manyFiles = true;
      gpg.format = "ssh"; # probably not needed with the signing.format now anymore, but better to be safe

      # diff and merge settings to use delta for diffs.
      diff = {
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
      };
      merge = {
        conflictStyle = "diff3";
      };
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
  };
}

# vim: ts=2:sw=2:expandtab

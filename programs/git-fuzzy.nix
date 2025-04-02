{ pkgs, misc, lib, config, options, ... }: {
  # Uses fzf to display some interactive info from git lists (status, diff, log, branch, reflog, stash, etc)

  home.packages = [
    # create an ad-hoc package derivation for git-fuzzy
    (
      pkgs.stdenv.mkDerivation {
        pname = "git-fuzzy";
        version = "9b6846f25f33c82a1b7af6e7c9a5a013eeb9b702"; # use the git commit hash as the version
        src = pkgs.fetchFromGitHub {
            owner = "bigH";
            repo = "git-fuzzy";
            rev = "9b6846f25f33c82a1b7af6e7c9a5a013eeb9b702";
            sha256 = "sha256-T2jbMMNckTLN7ejH+Fl2T4wAALGExiE3+DohZjxa1y4=";
            #sha256 = lib.fakeSha256;
          };

          dontBuild = true; # it's just a shell script, nothing to build
          # It has both a lib and bin directory, but the lib directory is scripts for internal use only.
          installPhase = ''
            mkdir -p $out/
            cp -r $src/lib $out/
            chmod +x $out/lib/*
            cp -r $src/bin $out/
            chmod +x $out/bin/*
          '';
      }
    )
  ];
}
# vim: ts=2:sw=2:expandtab
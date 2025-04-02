{ pkgs, misc, lib, config, options, ... }: {

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
          # install is just copying the files from the src bin folder into the output bin folder and making it executable
          installPhase = ''
            mkdir -p $out/bin
            cp -r $src/bin/* $out/bin/
            chmod +x $out/bin/*
          '';
      }
    )
  ];
}
# vim: ts=2:sw=2:expandtab
{ pkgs, misc, lib, config, options, inputs, ... }: {

  # The real git-agecrypt has a severe bug that causes it to read any git config keys with the substring "identity" in it as
  # a git-agecrypt identity (rather than only the git-agecrypt.config.identity values).

  home = {
    packages = [
      # Moved to a flake input that provides an overlay replacing the git-agecrypt package.
      # This allows us to use the --input-from option on our flake during setup on a new system.
      pkgs.git-agecrypt
  
      ## Override the git-agecrypt package source to point to the code that fixes it.
      #(pkgs.git-agecrypt.overrideAttrs (oldAttrs: {
      #  version = "f230f9dcc5da431e829c3978b985537d7efa47d8"; # use the git commit hash as the version for this
      #  src = pkgs.fetchFromGitHub {
      #    owner = "mtalexan";
      #    repo = "git-agecrypt";
      #    rev = "f230f9dcc5da431e829c3978b985537d7efa47d8";
      #    sha256 = "sha256-XQjuxGNkd40tNyjur/vjTtFuqZq5AooaTnp9do0/PIA=";
      #    #sha256 = lib.fakeSha256;
      #  };
      #}))
    ];

    # Add a home-manager activation hook that will run 'git agecrypt init' in the config directory this flake came from.
    # The exact path to the git-agecrypt binary is hardcoded into the local repo gitconfig, and needs to be manually updated.
    activation = {
      gitAgecryptInit = lib.hm.dag.entryAfter [ "installPackages" ] ''
        run ${lib.getExe' pkgs.git-agecrypt "git-agecrypt"} -C ${lib.escapeShellArg config.custom.configdir} agecrypt init
      '';
    };
  };
}
# vim: ts=2:sw=2:expandtab
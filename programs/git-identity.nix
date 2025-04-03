{ pkgs, misc, lib, config, options, ... }: {
  
  # Modified the git-identity tool to fix the help text and put the git config values under 'git-identity.<ident_name>' in the global
  # config, and 'git-identity.current' for the current identity in the local config.
  # This avoids conflicts with many other tools that try to use the 'user.identity'.

  home.packages = [
    pkgs.git-identity
    ## Override the git-identity package source to point to the code that fixes it.
    #(pkgs.git-identity.overrideAttrs (oldAttrs: {
    #  version = "f6c3c1cbbd752d83f79e307c1fc334dda969ea4d"; # use the git commit hash as the version for this
    #  src = pkgs.fetchFromGitHub {
    #    owner = "mtalexan";
    #    repo = "git-identity";
    #    rev = "f6c3c1cbbd752d83f79e307c1fc334dda969ea4d"; # latest on the 'fixed' branch
    #    sha256 = "sha256-pYHYySHn6hblGB1e1cD29m4go622DMcyUEt/O8p3H+w=";
    #    #sha256 = lib.fakeSha256;
    #  };
    #}))
  ];
}
# vim: ts=2:sw=2:expandtab
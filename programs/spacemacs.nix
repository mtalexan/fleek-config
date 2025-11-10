{ pkgs, misc, lib, config, inputs, ... }: {
  # This uses the nix-community overlay for emacs. https://github.com/nix-community/emacs-overlay
  #  Elpa and Melpa are available thru this, as are special builds of emacs itself.
  # See here for details: https://nixos.wiki/wiki/Emacs

  home.packages = [
    pkgs.emacs-unstable
    # spacemacs requires these fonts in order to work correctly
    pkgs.nanum-gothic-coding
    pkgs.nerd-fonts.hack
    pkgs.nerd-fonts.iosevka-term
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
    # Enable these if ussing spacemacs.
    pkgs.emacsPackages.nerd-icons
    pkgs.emacsPackages.all-the-icons-nerd-fonts
  ];

  # This is how to get the static config from spacemacs, but then turn it into a symlinked folder that can be modified.
  home.file.".emacs.d" = {
    enable = true;
    force = true;
    # create a symlink for every individual file. This lets us keep other things in the directory
    # that weren't part of the repo itself, like a qelpa package cache.
    recursive = true;
    source = pkgs.fetchFromGitHub {
      owner = "syl20bnr";
      repo = "spacemacs";
      rev = "9542f415149c2d98cc45cfa789f63d9a43912232";
      sha256 = "sha256-IqlnL9ItAima24Er9VS0Rrgopx+GO4akORKlPYEAkyM=";
      #sha256 = lib.fakeSha256;
    };
  };

  # Create a symlink ~/.spacemacs.d that redirects thru a few different symlinks) to the real on-disk path of the spacemacs.d folder next to this file.
  # The config.lib.file.mkoutOfStoreSymlink will do this for whatever file you pass it.
  # However, nix paths (like ./spacemacs.d) can only refer to files within the flake after it's been captured into the nix-store.
  # And since all flake evaluation only happens after the files have been copied into that nis-store, there is no way for nix to
  # construct the path to the code the flake in the store was copied from. It just has to be hardcoded as a path to where the flake code is stored.
  home.file.".spacemacs.d".source =  config.lib.file.mkOutOfStoreSymlink "${config.custom.configdir}/programs/spacemacs.d";

  # WARNING: emacs installed via Nix suffers from an issue on SSSD systems where it's unaware of the SSSD users, so libnss lookups
  #          will get './~$USER' as the users home folder instead of what's correct.  To solve this specifcially for
  #          emacs, we can call 'emacs --user ""' and it works to find the correct home folder.
  home.shellAliases = {
    "emacs" = ''emacs --user "" '';
  };
}

# vim: ts=2:sw=2:expandtab

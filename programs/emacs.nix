{ pkgs, misc, lib, ... }: {
  # This uses the nix-community overlay for emacs. https://github.com/nix-community/emacs-overlay
  #  Elpa and Melpa are available thru this, as are special builds of emacs itself.
  # See here for details: https://nixos.wiki/wiki/Emacs

  # WARNING: emacs suffers from an issue on SSSD systems where it's unaware of the SSSD users, so libnss lookups
  #          will get './~$USER' as the users home folder instead of what's correct.  To solve this specifcially for
  #          emacs, we can call 'emacs --user ""' and it works to find the correct home folder.
  home.shellAliases = {
    "emacs" = ''emacs --user "" '';
  };

  # To run the emacs daemon, uncomment this.
  # But settings will need to be manually matched between the daemon and the non-daemon
  #services.emacs = {
  #  enable = true;
  #}

  programs.emacs = {
    enable = true;

    # Warning: the emacsPgtk ("pure gtk") is really buggy with copy-paste, always opens with a warning dialog, and won't retain resize.
    # Use emacs-unstable for all the standard stuff and rely on XWayland, without a GTK dependency (GTK version is also slightly older).
    package = pkgs.emacs-unstable;

    # lines to add to the default init file
    #extraConfig = ''
    #'';

    # extra packages to add via nix.  These are all pkgs.emacsPackages.* or Elpa/Melpa packages
    extraPackages = epkgs: [
      epkgs.lsp-bridge
    ];

    # Override packages from the emacs package set
    #overrides = self: super: {
    #  haskell-mode = self.melpaPackages.haskell-mode;
    #};
  };
}

# vim: sw=2:expandtab

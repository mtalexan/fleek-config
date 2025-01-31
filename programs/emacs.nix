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

    # Use the emacsWithPackagesFromUsePackage wrapper so the use-package calls in the config will
    # be parsed and the package automatically included as if they'd been listed under extraPackages.
    package = (pkgs.emacsWithPackagesFromUsePackage {
      # Warning: the emacsPgtk ("pure gtk") is really buggy with copy-paste, always opens with a warning dialog, and won't retain resize.
      # Use emacs-unstable for all the standard stuff and rely on XWayland, without a GTK dependency (GTK version is also slightly older).
      package = pkgs.emacs-unstable;
      # This can be a *.org file named either init.org, or config.org that has tangle code blocks enabled in it.
      # If using org mode with tangling, set 'tangle: t' and do not specify the file name since the builder will expect the
      # tangled output to always match the base name of the *.org file (which is what that setting does when no file name is specified).
      # Alternatively it can just be a direct init.el or config.el.
      # Path is relative to this file.
      config = config.org;

      # Extra packages to add via nix.  These are all pkgs.emacsPackages.* or Elpa/Melpa packages.
      # Only add if there isn't a use-package definition for it in the config file.
      extraPackages = epkgs: [
        epkgs.use-package

        # TODO: Move these into the config.org file
        epkgs.lsp-bridge
        epkgs.treesit-auto
        epgks.treemacs
        epkgs.treemacs-nerd-icons
        epkgs.treemacs-magit
        epkgs.treemacs-icons-dired
        epkgs.treemacs-all-the-icons
      ];

      ## Optionally override derivations.
      #override = epkgs: epkgs // {
      #  somePackage = epkgs.melpaPackages.somePackage.overrideAttrs(old: {
      #     # Apply fixes here
      #  });
      #};
    });
  };
}

# vim: ts=2:sw=2:expandtab

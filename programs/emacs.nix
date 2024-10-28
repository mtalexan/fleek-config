{ pkgs, misc, lib, ... }: {
  # This uses the nix-community overlay for emacs. https://github.com/nix-community/emacs-overlay
  #  Elpa and Melpa are available thru this.
  #  emacs-git and emacs-unstable are also avaialable as optional alternatives.
  # 


  # To run the emacs daemon.
  # But settings will need to be manually matched between the daemon and the non-daemon
  #services.emacs = {
  #  enable = true;
  #}

  programs.emacs = {
    enabled = true;
    # make it available, but don't make it the default editor
    defaultEditor = false;

    # optional alternative
    # package = pkgs.emacs-gtk;

    # lines to add to the default init file
    #extraConfig = ''
    #'';

    # extra packages to add via nix
    #extraPackages = epkgs: [
    #  epkgs.emms
    #  epkgs.magit
    #];

    # Override packages from the emacs package set
    #overrides = self: super: {
    #  haskell-mode = self.melpaPackages.haskell-mode;
    #};
  };
}

# vim: sw=2:expandtab

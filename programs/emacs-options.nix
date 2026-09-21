{ lib, ... }: {
  options.custom.emacs = {
    sssd_workaround = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''Add an alias for emacs that works around emacs' inability to properly interact with SSSD users when called normally'';
    };
    siteConfigOrg = lib.mkOption {
      # This must be type 'lines' and not 'str' so we can use lib.mkDefault, lib.mkBefore, and lib.mkAfter to construct it.
      type = lib.types.lines;
      # Set no default here, we set it in the config block with lib.mkDefault instead.
      default = "";
      description = ''
        Text of the site-config.org file to tangle for use as the Emacs config.
        Designed to be used with lib.mkMerge, lib.mkOrder 1000 (default), lib.mkBefore, and lib.mkAfter to construct the full file text.
        The tangled version of this is installed as a site-lisp/default.el file for Emacs to load at startup.
        WARNING: All use-package directives must be included in this file so the packages can be automatically parsed and installed with
                 Nix.
        WARNING: There are restrictions on certain values/variables/settings that are only allowed to be set in the user-specific config.
                 Those must be added to the custom.emacs.configEl option instead.
        '';
      example = ''
        config.custom.emacs.siteConfigOrg = lib.mkMerge [
          (lib.mkBefore ''''
            #+TITLE: My Emacs Config

            * Basic Settings
            #+begin_src emacs-lisp :tangle yes
            ;; Basic settings here
            #+end_src
          '''')
          # default priority order
          (lib.mkOrder 1000 ''''
            * Main Config
            #+begin_src emacs-lisp :tangle yes
            ;; Main config here
            #+end_src
          '''')
          (lib.mkAfter ''''
            * Additional Settings
            #+begin_src emacs-lisp :tangle yes
            ;; Additional settings here
            #+end_src
          '''')
        ];
      '';
    };
    configEl = lib.mkOption {
      # This must be type 'lines' and not 'str' so we can use lib.mkDefault, lib.mkBefore, and lib.mkAfter to construct it.
      type = lib.types.lines;
      # Set no default here, we set it in the config block with lib.mkDefault instead.
      default = "";
      description = ''
        Text of the init.el file to generate in the .emacs.d/ user folder.
        Designed to be used with lib.mkMerge, lib.mkOrder 1000 (default), lib.mkBefore, and lib.mkAfter to construct the full file text.
        WARNING: All use-package directives must be included in the custom.emacs.siteConfigOrg so the packages can be parsed and installed
                 with Nix.
        This setting is primarily just for settings that are only allowed to be set at in the user-specific config.
        '';
      example = ''
        config.custom.emacs.siteConfigOrg = lib.mkMerge [
          # default priority order
          (lib.mkOrder 1000 ''''
            ;; Can only be set in user-specific config
            (setq some-variable some-value)
          '''')
        ];
      '';
    };

  };
}
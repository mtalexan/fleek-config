{ lib, ... }: {
  options.custom.emacs = {
    pythonServer = lib.mkOption {
      type = lib.types.enum [ "basedpyright" "ty" ];
      default = "basedpyright";
      description = "Common Python Eglot server profile.";
    };
    sssd_workaround = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''Add an alias for emacs that works around emacs' inability to properly interact with SSSD users when called normally'';
    };
    commonEl = lib.mkOption {
      # lines, not str, so mkBefore, mkAfter, and mkOrder can build the file.
      type = lib.types.lines;
      default = "";
      description = ''
        Elisp written to ~/.emacs.d/common.nix.el and loaded before the chezmoi common.org.
        Use this for settings that must contain Nix store paths.
        use-package forms here are installed from the emacs overlay.
        mkMerge, mkBefore, mkAfter, and mkOrder compose the text.
      '';
      example = ''
        config.custom.emacs.commonEl = lib.mkMerge [
          (lib.mkBefore ''''
            (setq fleek-common-early t)
          ''')
          (lib.mkAfter ''''
            (setq fleek-common-late t)
          ''')
        ];
      '';
    };
    hostEl = lib.mkOption {
      # lines, not str, so mkBefore, mkAfter, and mkOrder can build the file.
      type = lib.types.lines;
      default = "";
      description = ''
        Elisp written to ~/.emacs.d/host.nix.el.
        Loaded after common.org and before the chezmoi host org.
        Use this for host settings that must contain Nix store paths.
        use-package forms here are installed from the emacs overlay.
        mkMerge, mkBefore, mkAfter, and mkOrder compose the text.
      '';
      example = ''
        config.custom.emacs.hostEl = ''''
          (setq fleek-host-setting t)
        '''';
      '';
    };
  };
}

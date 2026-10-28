{ pkgs, lib, config, fleekConfigName, ... }:
# Emacs loads five files, later ones overriding earlier ones:
#   1. ~/.emacs.d/common.nix.el from custom.emacs.commonEl
#   2. ~/.emacs.d/common.org from chezmoi
#   3. ~/.emacs.d/host.nix.el from custom.emacs.hostEl
#   4. ~/.emacs.d/hosts/<host>_<user>.org from chezmoi
#   5. ~/.emacs.d/custom.el, which Emacs writes via custom-file
#
# use-package forms in the first four are installed from the emacs overlay.
# custom.el is not. package-install writes package files under ~/.emacs.d/elpa
# and records them in custom.el.
#
# defaultInitFile stays false. Turning it on loads a store copy of the config
# as site-lisp/default.el, so edits to the chezmoi org files do not apply, and
# those files would also load a second time from init.el.
let
  serverProfiles = import ./emacs/languages.nix {
    inherit pkgs lib;
    pythonServer = config.custom.emacs.pythonServer;
  };
  serverSettings = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: profile: "(setq fleek-eglot-${name}-command '(${lib.concatMapStringsSep " " builtins.toJSON profile.command}))")
    serverProfiles);
  parts = builtins.match "^(.*)@(.*)$" fleekConfigName;
  hostKey =
    if parts == null then
      throw "fleekConfigName must be user@host, got: ${toString fleekConfigName}"
    else
      "${builtins.elemAt parts 1}_${builtins.elemAt parts 0}";

  commonOrgText = builtins.readFile ../chezmoi/dot_emacs.d/common.org;
  hostOrgPath = ../chezmoi/dot_emacs.d/hosts + "/${hostKey}.org";
  hostOrgText = if builtins.pathExists hostOrgPath then builtins.readFile hostOrgPath else "";

  # The overlay parses one config. A bare elisp string makes it treat org
  # markup as elisp, so the Nix elisp is wrapped into the same org document.
  isBlank = text: builtins.match "[[:space:]]*" text != null;
  orgBabel = elisp:
    if isBlank elisp then ""
    else ''
      #+begin_src emacs-lisp :tangle yes
      ${elisp}
      #+end_src
    '';

  parsedConfigOrg = pkgs.writeText "emacs-packages.org" ''
    ${orgBabel config.custom.emacs.commonEl}
    ${commonOrgText}
    ${orgBabel config.custom.emacs.hostEl}
    ${hostOrgText}
  '';

  myEmacsPackageWithConfig = pkgs.emacsWithPackagesFromUsePackage {
    package = pkgs.emacs-unstable;
    override = epkgs: epkgs // { };
    extraEmacsPackages = epkgs: with epkgs; [
      use-package
      org
      corfu
      cape
      eldoc-box
    ] ++ [
      (treesit-grammars.with-grammars (g: [ g.tree-sitter-tsx g.tree-sitter-typescript g.tree-sitter-javascript g.tree-sitter-jsdoc g.tree-sitter-toml ]))
      adoc-mode
      basic-mode
      bitbake
      cil-mode
      clojure-mode
      cmake-mode
      coffee-mode
      csharp-mode
      cython-mode
      dart-mode
      dockerfile-mode
      dts-mode
      ess
      fsharp-mode
      go-mode
      groovy-mode
      hcl-mode
      jq-mode
      json-mode
      julia-mode
      just-mode
      kconfig-mode
      kotlin-mode
      lua-mode
      markdown-mode
      mermaid-mode
      nix-mode
      php-mode
      plantuml-mode
      powershell
      raku-mode
      rbs-mode
      rpm-spec-mode
      rust-mode
      shader-mode
      swift-mode
      systemd
      typescript-mode
      wat-mode
      web-mode
      xquery-mode
      yaml-mode
    ];
    alwaysEnsure = true;
    alwaysTangle = false;
    defaultInitFile = false;
    config = parsedConfigOrg;
  };

  initEl = ''
    ;;; -*- lexical-binding: t -*-
    ;; Emacs only honors these from the user init file.
    (setq inhibit-startup-message t)
    (setq inhibit-startup-screen t)

    ;; Customize and package-install write this file. It is not chezmoi-managed.
    (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
    (setq package-user-dir (expand-file-name "elpa" user-emacs-directory))

    (require 'use-package)
    (setq use-package-always-ensure nil)

    (require 'org)
    (require 'ob-tangle)

    (defun fleek-emacs-file-blank-p (file)
      (with-temp-buffer
        (insert-file-contents file)
        (string-blank-p (buffer-string))))

    (defun fleek-emacs-load-el (file)
      (when (and (file-exists-p file)
                 (not (fleek-emacs-file-blank-p file)))
        (load file)))

    (defun fleek-emacs-load-org (file)
      (when (file-exists-p file)
        (org-babel-load-file file)))

    (fleek-emacs-load-el (expand-file-name "common.nix.el" user-emacs-directory))
    (fleek-emacs-load-org (expand-file-name "common.org" user-emacs-directory))
    (fleek-emacs-load-el (expand-file-name "host.nix.el" user-emacs-directory))
    (fleek-emacs-load-org (expand-file-name "hosts/${hostKey}.org" user-emacs-directory))

    (when (file-exists-p custom-file)
      (load custom-file))
  '';
in {
  config = {
    custom.emacs.commonEl = lib.mkBefore ''
      ;;; -*- lexical-binding: t -*-
      ${serverSettings}
      (with-eval-after-load 'rust-rustfmt
        (setq rust-rustfmt-bin "${pkgs.rustfmt}/bin/rustfmt"))
    '';
    home.packages = [
      pkgs.nanum-gothic-coding
      pkgs.nerd-fonts.hack
      pkgs.nerd-fonts.iosevka-term
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.symbols-only
    ];

    home.file.".emacs.d/common.nix.el".text = config.custom.emacs.commonEl;
    home.file.".emacs.d/host.nix.el".text = config.custom.emacs.hostEl;
    home.file.".emacs.d/init.el".text = initEl;
    home.file.".emacs.d/early-init.el".text = ''
      ;;; -*- lexical-binding: t -*-
      ;; rpm-spec-mode autoloads expand a compilation-mode definition.
      (require 'compile)
    '';

    programs.emacs = {
      enable = true;
      package = myEmacsPackageWithConfig;
    };

    # On SSSD, Emacs libnss lookups use ./~$USER unless --user "" is passed.
    home.shellAliases = lib.mkIf config.custom.emacs.sssd_workaround {
      "emacs" = ''${config.programs.emacs.package}/bin/emacs --user "" '';
    };

    custom.chezmoi.templates.emacs.enable = true;
  };
}

# vim: ts=2:sw=2:expandtab

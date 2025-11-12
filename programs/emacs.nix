{ pkgs, misc, lib, config, inputs, ... }: {
  # This uses the nix-community overlay for emacs. https://github.com/nix-community/emacs-overlay
  #  Elpa and Melpa are available thru this, as are special builds of emacs itself.
  # See here for details: https://nixos.wiki/wiki/Emacs
  # We use the emacsWithPackagesFromUsePackage from the overlay as our "package" to have it automatically generate most of our config, and
  # automatically parse out the emacs packages declared in our config with 'use-package'.
  #
  # The config is split into 3 parts, the main nix-defined portion that's loaded first, the Emacs GUI-generated custom.el file that's modified
  # by the emacs menus, and a writeable.org file that lets us test out changes before adding them to the main nix config.
  #
  # The nix-defined config is set using lib.mkDefault, lib.mkBefore, and lib.mkAfter on the config.custom.emacs.configOrg option.

  options.custom.emacs = {
    configOrg = lib.mkOption {
      # This must be type 'lines' and not 'str' so we can use lib.mkDefault, lib.mkBefore, and lib.mkAfter to construct it.
      type = lib.types.lines;
      # Set no default here, we set it in the config block with lib.mkDefault instead.
      default = "";
      description = "Path to the emacs configuration org-mode file.";
    };
  };

  config = {
    home.packages = [
      # Add some nice fonts so we can use them in the emacs config.
      pkgs.nanum-gothic-coding
      pkgs.nerd-fonts.hack
      pkgs.nerd-fonts.iosevka-term
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.symbols-only

      # Add all the language-servers from the flake
      inputs.language-servers.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # WARNING: emacs installed via Nix suffers from an issue on SSSD systems where it's unaware of the SSSD users, so libnss lookups
    #          will get './~$USER' as the users home folder instead of what's correct.  To solve this specifcially for
    #          emacs, we can call 'emacs --user ""' and it works to find the correct home folder.
    home.shellAliases = {
      "emacs" = ''emacs --user "" '';
    };

    # Create a symlink ~/.emacs.d/writeable.org that redirects thru a few different symlinks to the real on-disk path of the file in the emacs folder
    # next to this file. The config.lib.file.mkoutOfStoreSymlink will do this for whatever file you pass it.
    # We make this one file writeable, but able to be tracked via Git, for changes that aren't yet ready to be adopted by the read-only nix config.org generation.
    # Note: there is also the custom.el file that emacs itself may generate which overrides the read-only nix config.org, but is overridden by this writeable.org file.
    home.file.".emacs.d/writeable.org".source =  config.lib.file.mkOutOfStoreSymlink "${config.custom.configdir}/programs/emacs/writeable.org";

    programs.emacs = {
      enable = true;

      # Use the emacs overlay's automatic support for use-package
      #package = pkgs.emacs-unstable;
      package = (pkgs.emacsWithPackagesFromUsePackage {
        # Emacs package to use as base, this is the latest that's not a nightly.
        package = pkgs.emacs-unstable;

        # Override package set if needed
        override = epkgs: epkgs // {
          # Add any custom package overrides here if needed
        };

        # Additional packages not declared with use-package in the config
        extraEmacsPackages = epkgs: with epkgs; [
          use-package
          org
        ];

        # Always ensure all the packages are installed upfront, don't wait to see
        # if they're ever enabled before installing them. This is un-lazying the install
        # for the packages.
        alwaysEnsure = true;

        # Don't force tangling, leave it to be per-block in the org file.
        # This lets us add examples of usage to the org file if needed.
        alwaysTangle = false;

        # Use the default auto-generated default.el that detects whether our config is a *.org or not and will
        # set it up for the tangled version if so.
        defaultInitFile = true;
        # Convert the inline text to a file named config.org in the .emacs.d folder
        config = pkgs.writeText "config.org" config.custom.emacs.configOrg;
      }); # end of pkgs.emacsWithPackagesFromUsePackage
    }; # end of programs.emacs

    # Set the bulk of our custom config here
    custom.emacs.configOrg = lib.mkMerge [
      (lib.mkDefault ''
        #+TITLE: Emacs Configuration

        * Introduction
        This is my literate Emacs configuration managed by Nix Home Manager.
        All code blocks with =:tangle yes= are automatically tangled to =init.el=.
        Packages declared with =use-package= are automatically installed by Nix.

        This overally emacs config is separated into 3 levels of configuration files:
        1. =config.org=: This file that is a read-only org-mode file defined by the Nix configuration.
        2. =custom.el=: A writeable file that the Emacs GUI will automatically created/modify based on changes within the info Menu settings.
        3. =writeable.org=: A writeable tangled org-mode file for testing custom changes before they're included in the Nix config.

        The files are loaded in the order listed, which results in later files taking precedence over earlier ones.


        * Core Settings
        ** Basic UI Configuration
        #+begin_src emacs-lisp :tangle yes
        ;; Disable startup screen
        (setq inhibit-startup-message t)

        ;; Line numbers
        (global-display-line-numbers-mode t)
        ;(setq display-line-numbers-type 'relative)

        ;; Disable line numbers for some modes
        (dolist (mode '(org-mode-hook
                      term-mode-hook
                      shell-mode-hook
                      eshell-mode-hook))
          (add-hook mode (lambda () (display-line-numbers-mode 0))))
        #+end_src

        ** Package System
        #+begin_src emacs-lisp :tangle yes
        ;; Initialize use-package
        (require 'use-package)
        (setq use-package-always-ensure nil)  ;; Nix manages packages
        #+end_src

        * LSP Configuration
        ** LSP Mode
        #+begin_src emacs-lisp :tangle yes
        (use-package lsp-mode
          :init
          (setq lsp-keymap-prefix "C-c l")
          :hook (
                ;; On-demand LSP activation for each language
                (rust-mode . lsp-deferred)
                (python-mode . lsp-deferred)
                (nix-mode . lsp-deferred)
                (go-mode . lsp-deferred)
                (typescript-mode . lsp-deferred)
                (javascript-mode . lsp-deferred)
                (sh-mode . lsp-deferred)
                (c-mode . lsp-deferred)
                (c++-mode . lsp-deferred)
                (java-mode . lsp-deferred)
                (yaml-mode . lsp-deferred)
                (lsp-mode . lsp-enable-which-key-integration))
          :commands (lsp lsp-deferred)
          :config
          (setq lsp-idle-delay 0.5
                lsp-log-io nil
                lsp-completion-provider :capf
                lsp-headerline-breadcrumb-enable nil))
        #+end_src

        ** LSP UI
        #+begin_src emacs-lisp :tangle yes
        (use-package lsp-ui
          :commands lsp-ui-mode
          :config
          (setq lsp-ui-doc-enable t
                lsp-ui-doc-position 'at-point
                lsp-ui-doc-delay 0.5
                lsp-ui-sideline-enable t
                lsp-ui-sideline-show-hover t
                lsp-ui-sideline-show-diagnostics t))
        #+end_src

        * Completion
        ** Company Mode
        #+begin_src emacs-lisp :tangle yes
        (use-package company
          :hook (prog-mode . company-mode)
          :bind (:map company-active-map
                ("<tab>" . company-complete-selection))
          :config
          (setq company-idle-delay 0.2
                company-minimum-prefix-length 1
                company-backends '((company-capf company-dabbrev-code))))
        #+end_src

        * Syntax Checking
        ** Flycheck
        #+begin_src emacs-lisp :tangle yes
        (use-package flycheck
          :hook (prog-mode . flycheck-mode)
          :config
          (setq flycheck-check-syntax-automatically '(save mode-enabled)))
        #+end_src

        * Project Management
        ** Projectile
        #+begin_src emacs-lisp :tangle yes
        (use-package projectile
          :diminish projectile-mode
          :config
          (projectile-mode +1)
          :bind-keymap
          ("C-c p" . projectile-command-map)
          :init
          (setq projectile-project-search-path '("~/projects/")))
        #+end_src

        ** Treemacs
        #+begin_src emacs-lisp :tangle yes
        (use-package treemacs
          :bind
          (:map global-map
                ("C-x t t" . treemacs)))

        (use-package treemacs-projectile
          :after (treemacs projectile))
        #+end_src

        * Version Control
        ** Magit
        #+begin_src emacs-lisp :tangle yes
        (use-package magit
          :bind ("C-x g" . magit-status)
          :config
          (setq magit-display-buffer-function
                #'magit-display-buffer-same-window-except-diff-v1))
        #+end_src

        * UI Enhancements
        ** Theme
        #+begin_src emacs-lisp :tangle yes
        (use-package doom-themes
          :config
          (setq doom-themes-enable-bold t
                doom-themes-enable-italic t)
          (load-theme 'doom-one t)
          (doom-themes-org-config))
        #+end_src

        ** Modeline
        #+begin_src emacs-lisp :tangle yes
        (use-package doom-modeline
          :init (doom-modeline-mode 1)
          :config
          (setq doom-modeline-height 25
                doom-modeline-bar-width 3
                doom-modeline-project-detection 'projectile))

        (use-package all-the-icons
          :if (display-graphic-p))
        #+end_src

        ** Which Key
        #+begin_src emacs-lisp :tangle yes
        (use-package which-key
          :init (which-key-mode)
          :diminish which-key-mode
          :config
          (setq which-key-idle-delay 0.3))
        #+end_src

        * Org Mode Configuration
        ** Basic Settings
        #+begin_src emacs-lisp :tangle yes
        (use-package org
          :config
          (setq org-ellipsis " ▾"
                org-hide-emphasis-markers t
                org-src-fontify-natively t
                org-src-tab-acts-natively t
                org-edit-src-content-indentation 0
                org-hide-block-startup nil
                org-src-preserve-indentation nil
                org-startup-folded 'content
                org-cycle-separator-lines 2))
        #+end_src

        * Language-Specific Settings
        ** Rust
        #+begin_src emacs-lisp :tangle yes
        (use-package rust-mode
          :mode "\\.rs\\'"
          :config
          (setq rust-format-on-save t))
        #+end_src

        ** Python
        #+begin_src emacs-lisp :tangle yes
        (use-package python-mode
          :mode "\\.py\\'")
        #+end_src

        ** Nix
        #+begin_src emacs-lisp :tangle yes
        (use-package nix-mode
          :mode "\\.nix\\'")
        #+end_src

        ** Go
        #+begin_src emacs-lisp :tangle yes
        (use-package go-mode
          :mode "\\.go\\'")
        #+end_src

        ** TypeScript
        #+begin_src emacs-lisp :tangle yes
        (use-package typescript-mode
          :mode "\\.ts\\'"
          :config
          (setq typescript-indent-level 2))
        #+end_src

        ** YAML
        #+begin_src emacs-lisp :tangle yes
        (use-package yaml-mode
          :mode "\\.ya?ml\\'")
        #+end_src

        ** Markdown
        #+begin_src emacs-lisp :tangle yes
        (use-package markdown-mode
          :mode "\\.md\\'")
        #+end_src

        * Keybindings
        ** Custom Keybindings
        #+begin_src emacs-lisp :tangle yes
        ;; Window navigation
        (global-set-key (kbd "C-c <left>")  'windmove-left)
        (global-set-key (kbd "C-c <right>") 'windmove-right)
        (global-set-key (kbd "C-c <up>")    'windmove-up)
        (global-set-key (kbd "C-c <down>")  'windmove-down)

        ;; Buffer management
        (global-set-key (kbd "C-x k") 'kill-this-buffer)
        #+end_src

        * Performance
        ** Garbage Collection
        #+begin_src emacs-lisp :tangle yes
        ;; Increase GC threshold for better performance
        (setq gc-cons-threshold (* 100 1024 1024))

        ;; Reset GC threshold after startup
        (add-hook 'emacs-startup-hook
                  (lambda ()
                    (setq gc-cons-threshold (* 20 1024 1024))))
        #+end_src
      '')

      # This has to be last in the file.
      (lib.mkAfter ''
        * Specify and load customization file.
        This section sets where emacs should write the customizations made via the GUI, and explicitly loads that file if present.

        #+begin_src emacs-lisp :tangle yes
        (let ((custom-config (expand-file-name "custom.el" user-emacs-directory)))
          (setq custom-file  custom-config)
          (when (file-exists-p custom-config)
            (load custom-config)))
        #+end_src

        * Load Writeable Configuration
        This section loads and tangles the writeable configuration file that can be
        modified outside of the Nix configuration.

        Be careful, the org file we're loading is a symlink to a different location, but we want the tangled output file to be in the folder
        with the symlink, not what the symlink is pointing to.  
        The =org-babel-load-file= automatically resolves the symlink before loading, so make sure the tangle directives in the org file
        list the full destination path explicitly.

        #+begin_src emacs-lisp :tangle yes
        ;; Load and tangle the writeable configuration if it exists.
        (let ((writeable-config (expand-file-name "writeable.org" user-emacs-directory)))
          (when (file-exists-p writeable-config)
            (org-babel-load-file writeable-config)))
        #+end_src
      '')
    ]; # end of custom.emacs.configOrg
  }; # end of config
}

# vim: ts=2:sw=2:expandtab

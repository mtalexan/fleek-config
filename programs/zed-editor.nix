{ pkgs, misc, lib, config, ... }: {
  # zed editor, but without the actual package.
  # Zed suffers from similar issues to VSCode, in that the language servers and extra data
  # it downloads for extensions don't work properly when Zed is a nix package.
  # 
  # NixGL with Vulkan=true is STRONGLY recommended for this package. You must set 'bad_vulkan = true' to avoid a pop up
  # on every Zed startup if you don't have working Vulkan support natively, or via nixGL.
  
  options.custom.zed-editor = with lib; {
    no_vulkan = mkEnableOption ''
      Vulkan support doesn't work or isn't sufficient on this system, so set the environment variable to disable the emulated GPU warning.
      **WARNING: If this is NOT set, the config.custom.nixGL.use_vulkan option will be force-enabled!**
    '';
    external_zed = mkEnableOption ''
      Don't use the zed-editor package from the nixpkgs repo wrapped with the nixGL wrapper, use an externally installed version.
    '';
    # Currently disabled in this config, default is now true
    static_config = mkEnableOption ''
      Generate a home-manager static config for Zed.
      **UNMAINTAINED**
      Zed explicitly does not support this. It assumes all settings are mutable and regularly changes the file!
    '';
    assistant = mkOption {
      type = types.enum [ "zed" "copilot"];
      default = "zed";
      description = ''
        The type of assistant to use for completion in Zed.
        Only used when static_config is true
        The default, 'zed', is the "Zeta AI" assistant available for free from Zed.
        The 'copilot' value is a Copilot enterprise license.
        The GitHub authentication login for these types conflicts, and cannot be used together.
        For 'zed' assistant, the Sign In button in the upper right of the window will need to be used
        at least once per install.
        For 'copilot' the 'assistant: show configuration` settings need to be opened and the GitHub Copilot engine
        logged into at least once per install.
      '';
    };
  };
  
  config = {
    # set the nixGL value to true if no_vulkan isn't set, otherwise leave it as-is.
    custom.nixGL.use_vulkan = if (!config.custom.zed-editor.no_vulkan) then true else config.custom.nixGL.use_vulkan;

    # If we're managing the config externally via the git repo folder, install the
    # packages zed needs to have externally installed.
    # Otherwise, these are part of the programs.zed-editor.extraPackages.
    home.packages =  lib.mkIf (!config.custom.zed-editor.static_config) (
      [
        # Nix language server has to be manually installed external to zed
        pkgs.nixd
        # needed by Basher extension
        pkgs.shellcheck
      ] ++
      # If external_config is enabled, and internal_zed is enabled, we install only zed-editor
      # (which uses the 'zeditor' CLI name instead of 'zed') but make it a version that works
      # properly with GPUs.
      ( if (!config.custom.zed-editor.external_zed)
        then
          # don't wrap the zed-editor with nixGL if there's no vulkan support. It will get forced to
          # use an incompatible GPU and won't even start
          if (config.custom.zed-editor.no_vulkan)
          then
            [
              pkgs.zed-editor
            ]
          else
            [
              (config.lib.nixGL.wrap pkgs.zed-editor)
            ]
        else
          []
      )
    );
    
    home.sessionVariables = lib.mkIf (config.custom.zed-editor.no_vulkan) {
      # If Vulkan support isn't available, working, or sufficient, this has to be set to disable the
      # pop up warning about using an emulated GPU that appears on every zed startup.
      ZED_ALLOW_EMULATED_GPU = "1";
    };
    
    #####################################################
    # Symlinked ~/.config/zed to git repo, if enabled
    #####################################################
    
    # Create a symlink ~/.config/zed that redirects (thru a few different symlinks) to the real on-disk path of the 
    # zed-editor folder next to this file.
    # The config.lib.file.mkoutOfStoreSymlink will do this for whatever file you pass it.
    # However, nix paths (like ./zed-editor) can only refer to files within the flake after it's been captured into the nix-store.
    # And since all flake evaluation only happens after the files have been copied into that nix-store, there is no way for nix to
    # construct the path to the code the flake in the store was copied from. It just has to be hardcoded as a path to where the flake code is stored.
    home.file = lib.mkIf (!config.custom.zed-editor.static_config) {
      ".config/zed".source =  config.lib.file.mkOutOfStoreSymlink "${config.custom.configdir}/programs/zed-editor";
    };
    
    
    #####################################################
    # Static home-manager config, if enabled
    #####################################################
    
    programs.zed-editor = lib.mkIf (config.custom.zed-editor.static_config) {
      enable = true;
      # Use the nixGL wrapper so the Vulkan support will theoretically work.
      # Also can enable integrated graphics offloading, which is far better than fallback emulated.
      package = config.lib.nixGL.wrap pkgs.zed-editor;
      
      extraPackages = [
        # the nix language server
        pkgs.nixd
        # needed by Basher extension
        pkgs.shellcheck
        # this doesn't exist, but Basher wants it for a prettifier
        #pkgs.shellfmt
      ];
    
      # don't allow remote connections
      installRemoteServer = false;
    
      # Custom theme definitions
      #themes = {};
        
      # The hardcoded list of extensions to install.
      # This is actually the "auto_install_extensions" list, and other extensions can be
      # installed manually on a system-by-system basis still from within Zed.
      # A full list of all extensions currently installed can be found with:
      #  jq -r '.extensions | map(.manifest.id)[]' ~/.local/share/zed/extensions/index.json
      # WARNING: Only these extensions are "synced", but others can be installed in Zed manually!
      # WARNING: Themes are included in this list!
      extensions = [
        "ansible"
        "asciidoc"
        "awk"
        "basedpyright"
        "basher"
        "bitbake"
        "blackfox"
        "blueprint"
        "caddyfile"
        "cargo-appraiser"
        "cargo-tom"
        "catppuccin"
        "codebook"
        "colored-zed-icons-theme"
        "colorizer"
        "csv"
        "dark-pop-ui"
        "devicetree"
        "docker-compose"
        "dockerfile"
        "elisp"
        "env"
        "fleet-themes"
        "git-firefly"
        "go-snippets"
        "golangci-lint"
        "gosum"
        "graphviz"
        "groovy"
        "haku-dark-theme"
        "haskell"
        "helm"
        "html"
        "ini"
        "java"
        "jinja2"
        "jsonnet"
        "just"
        "kconfig"
        "latex"
        "log"
        "lua"
        "make"
        "markdown-oxide"
        "mermaid"
        "meson"
        "modest-dark"
        "nebula-pulse"
        "neocmake"
        "nginx"
        "nickel"
        "ninja"
        "nix"
        "one-dark-darkened"
        "one-dark-pro"
        "one-dark-pro-max"
        "org"
        "perl"
        "php"
        "plantuml"
        "powershell"
        "proto"
        "pylsp"
        "python-refactoring"
        "python-requirements"
        "qml"
        "r"
        "racket"
        "rpmspec"
        "ruby"
        "scala"
        "scheme"
        "snippets"
        "ssh-config"
        "strace"
        "terraform"
        "tmux"
        "toml"
        "typos"
        "visual-assist-dark"
        "vitesse-theme-refined"
        "xml"
        "zedokai"
        "zig"
      ];
      
      #########################
      # User Keymap
      #########################
      
      # Merged with the Zed defaults. Later config overrides early.
      # The same context can be defined any number of times, with the later settings winning.
      userKeymaps = [
        # Zed keymap
        #
        # For information on binding keys, see the Zed
        # documentation: https://zed.dev/docs/key-bindings
        #
        # To see the default key bindings run `zed: open default keymap`
        # from the command palette.
        # 
        # The same binding context can appear more than once.

        #### Global binding fixes
        {
          bindings = {
              # unmap ctrl+q as quit without prompt. It's too easy to hit accidentally
              ctrl-q = null;
          };
        }
        
        #### Next/Previous find match alt-n alt-p
        {
          context = "Editor";
          bindings = {
              # next find match
              alt-n = "search::SelectNextMatch";
              # previous find match
              alt-p = "search::SelectPreviousMatch";
          };
        }
        
        
        #### Correct Shift-tab as outdent (context-aware), not backtab (unaware)
        {
          context = "Editor";
          bindings = {
            shift-tab = "editor::Outdent";
          };
        }
        
        #### Correct "VSCode bindings" for block select. 
        # It incorrectly believes it's shift-alt-*, but it's actually ctrl-shift-*
        {
          context = "Editor";
          bindings = {
              ctrl-shift-up = "editor::AddSelectionAbove";
              ctrl-shift-down = "editor::AddSelectionBelow";
          };
        }
        
        #### Allow tab switcher to pick using just arrow keys
        {
          context = "TabSwitcher";
          bindings = {
              #normally ctrl-up/down, allow pure directional
              up = "menu::SelectPrevious";
              down = "menu::SelectNext";
          };
        }
        
        #### Ergo Mode bindings. 
        #   alt-i=up, alt-k=down, alt-j=left, alt-l=right
        #   alt-ctrl-j=ctrl-left, alt-ctrl-l=ctrl-right
        #   alt-shift-i=pageup, alt-shift-k=pagedown
        {
          context = "Picker || menu";
          bindings = {
              #up
              alt-i = "menu::SelectPrevious";
              #down
              alt-k = "menu::SelectNext";
          };
        }
        {
          context = "Editor";
          bindings = {
              #up
              alt-i = "editor::MoveUp";
              #home
              alt-u = ["editor::MoveToBeginningOfLine" { stop_at_soft_wraps = true; stop_at_indent = true; } ];
              #down
              alt-k = "editor::MoveDown";
              #end
              alt-o = ["editor::MoveToEndOfLine" { stop_at_soft_wraps = true; } ];
              #left
              alt-j = "editor::MoveLeft";
              #right
              alt-l = "editor::MoveRight";
              #ctrl-left
              alt-ctrl-j = "editor::MoveToPreviousWordStart";
              #ctrl-right
              alt-ctrl-l = "editor::MoveToNextWordEnd";
          };
        }
        {
          context = "ContextStrip";
          bindings = {
              #up
              alt-i = "agent::FocusUp";
              #right
              alt-l = "agent::FocusRight";
              #left
              alt-j = "agent::FocusLeft";
              #down
              alt-k = "agent::FocusDown";
          };
        }
        {
          context = "ProjectSearchBar > Editor";
          bindings = {
              #up
              alt-i = "search::PreviousHistoryQuery";
              #down
              alt-k = "search::NextHistoryQuery";
          };
        }
        #ignore ApplicationMenu directions, the alt-* has a special meaning there
        {
          #sublime
          context = "Editor";
          bindings = {
              #left
              ctrl-alt-j = "editor::MoveToPreviousSubwordStart";
              #right
              ctrl-alt-l = "editor::MoveToNextSubwordEnd";
              #left
              ctrl-alt-shift-j = "editor::SelectToPreviousSubwordStart";
              #right
              ctrl-alt-shift-l = "editor::SelectToNextSubwordEnd";
          };
        }
        {
          context = "Editor && edit_prediction";
          bindings = {
              #unbind alt-l, we don't want movement to the right to auto-complete
              alt-l = null;
          };
        }
        {
          context = "Editor && edit_prediction_conflict";
          bindings = {
              #unbind alt-l, we don't want movement to the right to auto-complete
              alt-l = null;
          };
        }
        {
          context = "Editor && (showing_code_actions || showing_completions)";
          bindings = {
              #up
              alt-i = "editor::ContextMenuPrevious";
              #down
              alt-k = "editor::ContextMenuNext";
              #pgup
              alt-shift-i = "editor::ContextMenuFirst";
              #home
              home = "editor::ContextMenuFirst";
              alt-u = "editor::ContextMenuFirst";
              #pgdown
              alt-shift-k = "editor::ContextMenuLast";
              #end
              end = "editor::ContextMenuLast";
              alt-o = "editor::ContextMenuLast";
          };
        }
        {
          #zed global bindings that are now used in contexts
          bindings = {
              ctrl-alt-i = null;
          };
        }
        {
          context = "Prompt";
          bindings = {
              #left
              alt-j = "menu::SelectPrevious";
              #right
              alt-l = "menu::SelectNext";
          };
        }
        {
          context = "OutlinePanel && not_editing";
          bindings = {
              #left
              alt-j = "outline_panel::CollapseSelectedEntry";
              #right
              alt-l = "outline_panel::ExpandSelectedEntry";
              #shift-down
              shift-alt-k = "menu::SelectNext";
              #shift-up
              shift-alt-i = "menu::SelectPrevious";
          };
        }
        {
          context = "ProjectPanel";
          bindings = {
              #left
              alt-j = "project_panel::CollapseSelectedEntry";
              #right
              alt-l = "project_panel::ExpandSelectedEntry";
              #shift-down
              shift-alt-k = "menu::SelectNext";
              #shift-up
              shift-alt-i = "menu::SelectPrevious";
          };
        }
        {
          context = "GitPanel && ChangesList";
          bindings = {
              #up
              alt-i = "menu::SelectPrevious";
              #down
              alt-k = "menu::SelectNext";
          };
        }
        {
          context = "GitCommit > Editor";
          bindings = {
              #normally set to generate a commit message, but it conflicts with ergo keys
              alt-l = null;
          };
        }
        {
          context = "GitPanel > Editor";
          bindings = {
              #normally set to generate a commit message, but it conflicts with ergo keys
              alt-l = null;
          };
        }
        {
          context = "Picker > Editor";
          bindings = {
              #up
              alt-i = "menu::SelectPrevious";
              #down
              alt-k = "menu::SelectNext";
          };
        }
        {
          context = "TabSwitcher";
          bindings = {
              #normally ctrl-up/down, we allowed pure directional too
              #up
              alt-i = "menu::SelectPrevious";
              #down
              alt-k = "menu::SelectNext";
          };
        }
      ];
      
      #########################
      # User Settings
      #########################

      # Settings are merged with the Zed defaults, so we only need overrides
      userSettings = {
        #### AI
        assistant = {
          version = 2;
          default_model = if (config.custom.zed-editor.assistant == "copilot")
            then {
                provider = "copilot_chat";
                model = "gpt-4o";
            }
            else {
              provider = "zed.dev";
              model = "claude-3-7-sonnet-latest";
            };
        };
        features = {
          # Undocumented setting for picking which provider is used for completion.
          # Can be set to any provider on `assistant: show configuration` or `zed`.
          # ONLY 1 GITHUB AUTHORIZATION WILL WORK PER INSTALL
          # The Zed GtiHub sign in and the Copilot sign in will silently fail if you're
          # currently logged into GitHub with the other.
          edit_prediction_provider = if (config.custom.zed-editor.assistant == "copilot") then "copilot" else "zed";
        };
        
        #### Appearance
        icon_theme = "Colored Zed Icons Theme Dark";
        ui_font_size = 15;
        buffer_font_size = 14;
        buffer_line_height = "standard";
        theme = {
          mode = "system";
          light = "One Light";
          dark = "Nebula Nova";
        };
        
        #### General
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        
        pane_split_direction_horizontal = "down";
        pane_split_direction_vertical = "right";
        wrap_guides = [80];
        show_whitespaces = "boundary";
        gutter = {
          folds = false;
        };
        indent_guides = {
          active_line_width = 2;
          coloring = "indent_aware";
        };
        seed_search_query_from_cursor = "selection";
        use_smartcase_search = true;
        project_panel = {
          entry_spacing = "standard";
        };
        collaboration_panel = {
          button = false;
        };
        message_editor = {
          auto_replace_emoji_shortcode = false;
        };
        autosave = { after_delay = { milliseconds = 500; }; };
        tabs = {
          git_status = true;
          file_icons = true;
          show_diagnostics = "errors";
        };
        file_finder = {
          modal_max_width = "large";
        };
        remove_trailing_whitespace_on_save = false;
        ensure_final_newline_on_save = false;
        format_on_save = "off";
        soft_wrap = "editor_width";
        diagnostics = {
          inline = {
            enabled = true;
            # only show inline errors, others are shown other ways
            max_severity = "error";
          };
        };
        git = {
          inline_blame = {
            show_commit_summary = true;
          };
        };
        journal = {
          hour_format = "hour24";
        };
        terminal = {
          shell = {
            program = "zsh";
          };
          line_height = "standard";
          detect_venv = "off";
          # max allowed is 100_000
          max_scroll_history_lines = 100000;
        };
      }; # end userSettings
    }; # end programs.zed-editor
  };
}

# vim: ts=2:sw=2:expandtab

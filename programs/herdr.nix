{ pkgs, misc, lib, config, herdrPlugins, ... }:
let
  # The herdr-annotate-full/lite plugin requires one of a few different clipboard tools to be available. But the
  # nix packaging of it doesn't include any of those tools with it. So create a wrapper for it that injects those tools as part
  # of the PATH of the plugin tool so it has them.
  # It defaults to using the wl-clipboard tools, but if they fail it falls back to the xclip tools automatically.
  herdrAnnotate = herdrPlugins.herdr-annotate-full.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      # The Linux manifest also uses the .exe filename for this native helper.
      wrapProgram $out/bin/herdr-annotate.exe \
        --prefix PATH : ${lib.makeBinPath [ pkgs.wl-clipboard pkgs.xclip ]}
    '';
  });

  # Local override for herdr's Copilot screen-scraping state detection, installed to
  # ~/.config/herdr/agent-detection/copilot.toml.
  # herdr does not merge this file with its own rules. It replaces the entire Copilot detection manifest
  # (bundled or auto-updated remote), so it must contain every upstream rule. It's built from the manifest
  # bundled in the herdr source plus our local rules from the patch. The patch only adds a rule that marks
  # the pane blocked while a plannotator plan review is open in the browser.
  # While this override exists, herdr's remote manifest updates for Copilot are ignored, so upstream rule
  # changes only arrive with herdr package updates. The build fails if the patch no longer applies.
  herdrCopilotManifest = pkgs.runCommand "herdr-copilot-manifest-${config.programs.herdr.package.version}" {
    nativeBuildInputs = [ pkgs.patch pkgs.jq config.programs.herdr.package ];
  } ''
    cp ${config.programs.herdr.package.src}/src/detect/manifests/github-copilot.toml github-copilot.toml
    chmod u+w github-copilot.toml
    if ! patch --fuzz=0 --no-backup-if-mismatch github-copilot.toml ${./herdr-copilot-plan-review.patch}; then
      echo "error: programs/herdr-copilot-plan-review.patch no longer applies to the Copilot detection manifest" >&2
      echo "       bundled in herdr ${config.programs.herdr.package.version} (src/detect/manifests/github-copilot.toml)." >&2
      echo "       Re-check the upstream rules and regenerate the patch." >&2
      exit 1
    fi

    # Check the patched manifest classifies sample Copilot screens as expected.
    export HOME=$PWD/home XDG_CONFIG_HOME=$PWD/config
    mkdir -p $HOME $XDG_CONFIG_HOME/herdr/agent-detection
    cp github-copilot.toml $XDG_CONFIG_HOME/herdr/agent-detection/copilot.toml
    cat > pending.txt <<'EOF'
     ○ Plan ready for review - **Do the thing** · summary: "- **Do the thing**"    9m 43s

     ~/project +1 -0
    ╻▄▄▄▄▄▄▄▄▄▄
    ┃
    ╹▀▀▀▀▀▀▀▀▀▀
     ◎ Working - plan · 34.2 KiB esc interrupt
    EOF
    cat > resolved.txt <<'EOF'
     ● Plan ready for review - **Do the thing** · summary: "- **Do the thing**"    9m 43s

     ● Edit  Edit src/main.rs

     ~/project +1 -0
    ╻▄▄▄▄▄▄▄▄▄▄
    ┃
    ╹▀▀▀▀▀▀▀▀▀▀
     ◎ Working · esc interrupt
    EOF
    check() {
      local state
      state=$(herdr agent explain --file "$1" --agent copilot --json | jq -r .state)
      if [ "$state" != "$2" ]; then
        echo "error: patched Copilot manifest classified $1 as '$state', expected '$2'" >&2
        exit 1
      fi
    }
    check pending.txt blocked
    check resolved.txt working

    cp github-copilot.toml $out
  '';

  ##########################################################################
  # Plugins to enable. Each entry is:
  #   plugin   - package from herdr-nix (herdrPlugins.*), https://github.com/lorenzorapetti/herdr-nix
  #   id       - plugin id, as used in action commands and pluginSettings
  #   bindings - list of { key, action, description } that become plugin_action keybindings.
  #              The action is the plugin-local action id and gets prefixed with the plugin id.
  #   settings - optional attrset written to the plugin's config file, null for none
  herdrPluginList = [
    {
      # Plannotator annotations
      plugin = herdrAnnotate;
      id = "annotate";
      bindings = [
        { key = "prefix+a"; action = "capture"; description = "annotate selected text"; }
        { key = "prefix+m"; action = "manage"; description = "manage annotations"; }
        { key = "prefix+c"; action = "copy-context"; description = "copy annotations with context"; }
        { key = "prefix+v"; action = "send-context"; description = "paste annotations and archive them"; }
        { key = "prefix+ctrl+o"; action = "open"; description = "open a file picker in the current folder to select file(s) for annotation"; }
        { key = "prefix+shift+o"; action = "last-newest"; description = "annotate the last message"; }
      ];

      # all config for this is part of the plannotator-tui, under the [herdr] key.
      settings = null;
    }
    {
      # Makes the agent sidebar structured and more useful
      plugin = herdrPlugins.herdr-radar;
      id = "herdr-radar";
      bindings =[];
      settings = null;
    }
    {
      # A jump-to-anything selector with fuzzy search and optional auto-titling.
      plugin = herdrPlugins.herdr-bar;
      id = "herdr-bar";
      bindings = [
        { key = "prefix+k"; action = "open"; description = "open the bar"; }
        # This might conflict sometimes, but we use it so frequently that it's better if it's easy to hit
        { key = "ctrl+k"; action = "open"; description = "open the bar"; }
      ];
      settings = {
        # Show tail of what's running in the workspace. Auto = only when wide enough.
        preview = "auto";
        mouse = true;
        # Automatically suppressed if alternative naming plugins are present
        auto_titles = true;
        # New agent session in workspace can replace the auto-title name
        follow_new_sessions = true;
        # The filter the bar opens with by default. Can always add prefix to quick jump to filters:
        #  @ agents
        #  % panes
        #  tabs
        #  $ shells
        #  ! blocked
        #  > actions (only if actions = true)
        #  all
        scope = "all";
        # If enabled, your current focus is the default selection on open. If false it's the last focused, which
        # allows you to alt+tab by opening then quickly pressing enter.
        select_current = false;
        # show plugin actions, and allow > quick filtering for them
        actions = true;
      };
    }
    # Currently broken due to a bug in the plugin tests that is timing dependent instead of deterministic.
    #{
    #  # Change reviewer with annotation support
    #  plugin = herdrPlugins.herdr-reviewr;
    #  id = "persiyanov.reviewr";
    #  bindings = [
    #    { key = "prefix+alt+r"; action = "toggle"; description = "toggle reviewr"; }
    #  ];
    #  settings = null;
    #}
    # Uses up too much real estate, and affects how tabs are opened/closed since it shows up as a separate tab pane.
    #{
    #  # Addiitonal sidebar with file explorer, file search/open, and VCS.
    #  plugin = herdrPlugins.herdr-sidebar;
    #  id = "herdr-sidebar";
    #  bindings = [
    #    { key = "prefix+ctrl+p"; action = "show-explorer"; description = "open/focus the sidebar explorer view w/o toggle"; }
    #    { key = "prefix+p"; action = "quick-open"; description = "open fuzzy file search"; }
    #  ];
    #  settings = null;
    #}
  ];
in {
  programs.herdr = {
    enable = true;
    # Settings aren't read-only, only the settings specified below will be overwritten,
    # and only on activation.
    mutableSettings = true;
    plugins = map (e: e.plugin) herdrPluginList;
    pluginSettings = lib.listToAttrs (map (e: lib.nameValuePair e.id e.settings)
      (lib.filter (e: e.settings != null) herdrPluginList));
    # See https://herdr.dev/docs/config-reference/
    settings = {
      experimental = {
        # put all pain history in the session so it can be restored
        pane_history = true;
      };
      theme = {
        name = "terminal";
      };
      ui = {
        toast = {
          # system notifications
          delivery = "system";
        };
        status_indicators = "symbols";
        # ctrl+right-click  passes the right-click thru to the agent
        right_click_passthrough_modifier = "ctrl";
      };
      update = {
        # tells you if there's a new version available
        version_check = true;
      };

      terminal = {
        # Use our built-in zsh for the shell explicitly, just like we do with Kitty
        default_shell = lib.getExe config.programs.zsh.package;
      };
      
      keys = {
        # we re-bound the default prefix+v
        split_vertical = "prefix+|";

        focus_pane_left = "prefix+left";
        focus_pane_right = "prefix+right";
        focus_pane_up = "prefix+up";
        focus_pane_down = "prefix+down";
        # normally cycles forward thru panes
        last_pane = "prefix+tab";

        new_tab = "prefix+t";
        
        command = lib.concatMap (e: map (b: {
          inherit (b) key description;
          type = "plugin_action";
          command = "${e.id}.${b.action}";
        }) e.bindings) herdrPluginList;
      };
    };
  };

  xdg.configFile."herdr/agent-detection/copilot.toml" = {
    source = herdrCopilotManifest;
    # A running server only rereads detection manifests on request. Fails harmlessly if no server is running.
    onChange = ''
      run ${lib.getExe config.programs.herdr.package} server reload-agent-manifests || true
    '';
  };

  # Needs to be after compinit is initialized
  programs.zsh.initContent = lib.mkMerge [ (lib.mkOrder 1000 (lib.concatLines [
    ''
      eval "$(herdr completion zsh)"
    ''
  ]))];

  programs.bash.initExtra = lib.concatLines [
    ''
    eval "$(herdr completion bash)"
    ''
  ];

  home.shellAliases = {
    # force setting the HERDR_AGENT variable when running copilot so it's recognized properly
    copilot = "HERDR_AGENT=copilot copilot";
  };
}
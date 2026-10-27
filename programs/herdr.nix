{ pkgs, misc, lib, config, herdrPlugins, ... }:
let
  # Plugins to enable. Each entry is:
  #   plugin   - package from herdr-nix (herdrPlugins.*), https://github.com/lorenzorapetti/herdr-nix
  #   id       - plugin id, as used in action commands and pluginSettings
  #   bindings - list of { key, action, description } that become plugin_action keybindings.
  #              The action is the plugin-local action id and gets prefixed with the plugin id.
  #   settings - optional attrset written to the plugin's config file, null for none
  herdrPluginList = [
    {
      # Plannotator annotations
      plugin = herdrPlugins.herdr-annotate-full;
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
    {
      # Addiitonal sidebar with file explorer, file search/open, and VCS.
      plugin = herdrPlugins.herdr-sidebar;
      id = "herdr-sidebar";
      bindings = [
        { key = "prefix+ctrl+p"; action = "show-explorer"; description = "open/focus the sidebar explorer view w/o toggle"; }
        { key = "prefix+p"; action = "quick-open"; description = "open fuzzy file search"; }
      ];
      settings = null;
    }
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
      keys.command = lib.concatMap (e: map (b: {
        inherit (b) key description;
        type = "plugin_action";
        command = "${e.id}.${b.action}";
      }) e.bindings) herdrPluginList;
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
    };
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
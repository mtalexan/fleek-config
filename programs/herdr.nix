{ pkgs, misc, lib, config, herdrPlugins, ... }:
let
  # Plugins to enable. Each entry is:
  #   plugin   - package from herdr-nix (herdrPlugins.*)
  #   id       - plugin id, as used in action commands and pluginSettings
  #   bindings - list of { key, action, description } that become plugin_action keybindings.
  #              The action is the plugin-local action id and gets prefixed with the plugin id.
  #   settings - optional attrset written to the plugin's config file, null for none
  herdrPluginList = [
    #{
    #  plugin = herdrPlugins.herdr-annotate-full;
    #  id = "annotate";
    #  bindings = [
    #    { key = "prefix+alt+a"; action = "capture"; description = "annotate selection"; }
    #    { key = "prefix+alt+m"; action = "manage"; description = "manage annotations"; }
    #    { key = "prefix+alt+c"; action = "copy-context"; description = "copy annotations"; }
    #    { key = "prefix+alt+d"; action = "open"; description = "review folder in plannotator"; }
    #    { key = "prefix+alt+l"; action = "last"; description = "review last agent message"; }
    #  ];
    #  settings = null;
    #}
    #{
    #  plugin = herdrPlugins.herdr-navigator;
    #  id = "herdr-navigator";
    #  bindings = [
    #    { key = "prefix+alt+o"; action = "open"; description = "open navigator"; }
    #    { key = "prefix+alt+p"; action = "open-side"; description = "open navigator in side pane"; }
    #    { key = "prefix+alt+b"; action = "jump-back"; description = "navigator jump back"; }
    #  ];
    #  settings = null;
    #}
    #{
    #  plugin = herdrPlugins.herdr-reviewr;
    #  id = "persiyanov.reviewr";
    #  bindings = [
    #    { key = "prefix+alt+r"; action = "toggle"; description = "toggle reviewr"; }
    #  ];
    #  settings = null;
    #}
    #{
    #  plugin = herdrPlugins.herdr-automatic-rename;
    #  id = "herdr-automatic-rename";
    #  bindings = [
    #    { key = "prefix+alt+n"; action = "reset"; description = "reset automatic names"; }
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

  home.sessionVariables = {
    # Do NOT make this a specific path to a plannotator-ui binary, or existing Copilot
    # sessions will break whenever we activate a new home-manager config.
    COPILOT_EDITOR = "plannotator-ui";
  };
}
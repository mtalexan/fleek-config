{ pkgs, misc, lib, config, options, ... }: {

  # The plannotator-copilot plugin's hook needs the plannotator binary.
  imports = [ ./plannotator.nix ];
  
  config = let
    cfg = config.custom.github-copilot-cli;
    hmCfg = config.programs.github-copilot-cli;

    # Marketplace sources (owner/repo, git URL, or local path) to register.
    # Registered names come from each marketplace.json, so they can't be set here.
    copilotMarketplaces = [
      "backnotprop/plannotator"
    ];

    # Plugin specs in plugin@marketplace form, exactly as passed to `copilot plugin install`.
    copilotPlugins = [
      "plannotator-copilot@plannotator"
    ];

    # Splits "plugin@marketplace" on the last '@'.
    parsePluginSpec = spec:
      let m = builtins.match "(.+)@([^@]+)" spec;
      in if m == null
        then throw "github-copilot-cli: plugin spec '${spec}' must be in plugin@marketplace form"
        else { name = builtins.elemAt m 0; marketplace = builtins.elemAt m 1; };

    # `marketplace list --json` shows GitHub sources as "GitHub: owner/repo".
    # Other source forms have no known display text and are handled by the add fallback.
    marketplaceListedSource = src:
      if builtins.match "[A-Za-z0-9-]+/[A-Za-z0-9._-]+" src != null then "GitHub: ${src}" else "";

    # Script that runs during home-manager activation. 
    # It makes sure the marketplaces and plugins are registered/installed, but does not remove any existing ones.
    # Copilot throws an error if you try to register or install something that's already present, so we have to
    # check to see if it's already present before trying to add it.
    copilotPluginsScript = ''
      _copilotPluginsCli() {
        COPILOT_HOME=${lib.escapeShellArg hmCfg.configDir} \
        PATH=${lib.makeBinPath [ pkgs.git pkgs.openssh pkgs.coreutils ]}:$PATH \
          ${pkgs.coreutils}/bin/timeout 300 ${lib.getExe hmCfg.package} "$@"
      }
    ''
    + lib.optionalString (copilotMarketplaces != [ ]) (''
      if ! _copilotMarketplaces=$(_copilotPluginsCli plugin marketplace list --json); then
        errorEcho "github-copilot-cli: failed to list plugin marketplaces"
        exit 1
      fi
    '' + lib.concatMapStrings (src: ''
      _copilotSrc=${lib.escapeShellArg src}
      _copilotListed=${lib.escapeShellArg (marketplaceListedSource src)}
      if [[ -n "$_copilotListed" ]] \
          && ${lib.getExe pkgs.jq} -e --arg s "$_copilotListed" 'any(.[]; .source == $s)' \
            <<<"$_copilotMarketplaces" >/dev/null; then
        verboseEcho "github-copilot-cli: marketplace $_copilotSrc already registered"
      elif _copilotOut=$(run _copilotPluginsCli plugin marketplace add "$_copilotSrc" 2>&1); then
        echo "github-copilot-cli: added marketplace $_copilotSrc"
      elif [[ "$_copilotOut" =~ Marketplace\ \"[^\"]+\"\ .*already ]]; then
        # The CLI exits non-zero when the marketplace is already registered.
        verboseEcho "github-copilot-cli: marketplace $_copilotSrc already registered"
      else
        errorEcho "github-copilot-cli: failed to add marketplace $_copilotSrc:"
        echo "$_copilotOut" >&2
        exit 1
      fi
    '') copilotMarketplaces)
    + lib.optionalString (copilotPlugins != [ ]) (''
      if ! _copilotPlugins=$(_copilotPluginsCli plugin list --json); then
        errorEcho "github-copilot-cli: failed to list plugins"
        exit 1
      fi
    '' + lib.concatMapStrings (spec: let p = parsePluginSpec spec; in ''
      if ${lib.getExe pkgs.jq} -e --arg n ${lib.escapeShellArg p.name} --arg m ${lib.escapeShellArg p.marketplace} \
          'any(.[]; .name == $n and .marketplace == $m)' <<<"$_copilotPlugins" >/dev/null; then
        verboseEcho "github-copilot-cli: plugin ${spec} already installed"
      elif _copilotOut=$(run _copilotPluginsCli plugin install ${lib.escapeShellArg spec} 2>&1); then
        echo "github-copilot-cli: installed plugin ${spec}"
      else
        errorEcho "github-copilot-cli: failed to install plugin ${spec}:"
        echo "$_copilotOut" >&2
        exit 1
      fi
    '') copilotPlugins);
  in {
    # Additive only. Plugins and marketplaces removed from the lists are left installed.
    home.activation.githubCopilotCliPlugins =
      lib.hm.dag.entryAfter [ "linkGeneration" "githubCopilotCliSettings" ] copilotPluginsScript;

    programs.github-copilot-cli = {
      enable = true;
      # if there are any programs.mcp.servers, use the settings too but with lower priority
      enableMcpIntegration = true;
      mcpServers = {} 
      // lib.mkIf cfg.plannotatorInbox.enable {
        # Adds the Plannotator Inbox as an MCP, though Copilot currently doesn't have any mode
        # where it serves a purpose.
        plannotator-inbox = {
          type = "local";
          command = lib.getExe config.custom.plannotator.package;
          args = [ "inbox" "mcp" ];
          tools = [ "*" ];
        };
      };
  
      # Settings are not read-only, they can be changed by the application.
      # But any settings specified here will overwrite the mutable ones on activation.
      # Only specify what you actually want to hardcode.
      mutableSettings = true;
      # see https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference#user-settings-copilotsettingsjson
      settings = {
        renderMarkdown = true;
        # This also includes first-party plugins. The CLI tool itself will always fail to update, so it's fine to enable this.
        autoUpdate = true;
        includeCoAuthoredBy = false;
        respectGitignore = false;
        # default is 50, max possible is 1000.
        commandHistoryMaxSize = 1000;
        # Don't allow the system to sleep while an agent is running.
        # WARNING: This also prevents locking, not just sleeping.
        keepAlive = "busy";
        workflows.maxConcurrentRuns = cfg.maxParallel;
        # disable all the OpenTelemetry
        telemetry.capture = {
          identity = false;
          policyDetail = false;
          prompts = false;
          responses = false;
          toolArguments = false;
          toolOutput = false;
        };

        # What to include in statusline
        footer = {
          showModelEffort = true;
          showDirectory = true;
          showBranch = true;
          showContextWindow = true;
          showQuota = true;
          showAiUsed = true;
          showAgent = true;
          showCodeChanges = true;
          showUsername = false;
          showSandbox = true;
          showYolo = true;
          showCiStatus = false;
          showSchedules = false;
          showPullRequest = false;
          # This semes to be the whatever random extras it wants to include
          showCustom = true;
        };
        
        # The default. But only a few things are actually clickable, so maybe this should be turned off instead?
        mouse = true;
        # Not the default, but necessary for being able to copy anything at all from the output when mouse = true.
        copyOnSelect = true;
        
        # needed for HydraFusion model support, and "assisted" permissions mode currently
        experimental = true;

        defaultMode = "plan";
        # Don't ask about every little thing.
        # There appears to be no real way to set this mode per-prompt(?)
        # Requires experimental = true
        defaultPermissionMode = "assisted";

        # When selecting just "auto", which is the default type: efficiency, balance, intelligence
        autoTier = "intelligence";
        planModel = "auto";

        # WARNING: The GPT-6.1 Sol model is broken and will hang forever whenever trying to start implementation of a plan.
        #          This occurs both when moving from Plan -> Implement, and when already in Implement and instructing it to
        #          simply implement the plan. In the latter case it fails by returning to plan mode for plan re-review.
        #          Auto mode currently selects this model pretty frequently, which causes this breakage as well.
        #model = "auto";
        # Requires experimental = true
        model = "hydrafusion";
        
        
      };
    };
  };
}
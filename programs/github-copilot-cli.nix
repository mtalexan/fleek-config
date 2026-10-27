{ pkgs, misc, lib, config, options, ... }: {

  
  config = let
    cfg = config.custom.github-copilot-cli;
  in {
    programs.github-copilot-cli = {
      enable = true;
      # if there are any programs.mcp.servers, use the settings too but with lower priority
      enableMcpIntegration = true;
      #mcpServers = {};
  
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

        # The default. But only a few things are actually clickable, so maybe this should be turned off instead?
        mouse = true;
        # Not the default, but necessary for being able to copy anything at all from the output when mouse = true.
        copyOnSelect = true;
        
        # needed for HydraFusion model support, and "assisted" permissions mode currently
        experimental = true;

        defaultMode = "plan";
        # Don't ask about every little thing.
        # There appears to be no real way to set this mode per-prompt(?)
        defaultPermissionMode = "assisted";

        # When selecting just "auto", which is the default type: efficiency, balance, intelligence
        autoTier = "intelligence";
        planModel = "auto";
        model = "hydrafusion";
        
      };
    };
  };
}
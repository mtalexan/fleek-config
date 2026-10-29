{ lib, ... }: {
  options.custom.github-copilot-cli = with lib; {
    maxParallel = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Maximum number of concurrent chats. Sets settings.workflows.maxConcurrentRuns.";
    };

    plannotator = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable the Plannotator plugin that uses the in-browser plugin for Plan review, and enables the
          /plannotator-review command to review and comment on changes.
        '';
      };
      
      inboxEnable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Register the Plannotator Inbox MCP so agents can message the centralized Inbox.
          This is not used for Plan reviews or change reviews (/plannotator-review), which still open
          their own blocking sessions.
          It's intended for autopilot-like modes where questions and info can be posted asynchronously
          from the agent. Copilot has no equivelent mode.
        '';
      };
    };
  };
}

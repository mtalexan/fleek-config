{ lib, ... }: {
  options.custom.github-copilot-cli = with lib; {
    maxParallel = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Maximum number of concurrent chats. Sets settings.workflows.maxConcurrentRuns.";
    };

    plannotatorInbox.enable = mkOption {
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
}

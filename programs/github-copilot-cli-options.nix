{ lib, ... }: {
  options.custom.github-copilot-cli = with lib; {
    maxParallel = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Maximum number of concurrent chats. Sets settings.workflows.maxConcurrentRuns.";
    };
  };
}

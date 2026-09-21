{ pkgs, misc, lib, config, options, ... }: {
  config = let
    cfg = config.custom.kilo;
    hasCopilotApi = builtins.hasAttr "copilot-api" options.custom;
    selectedApiKey = if cfg.backend == null then null else cfg.api_keys.${cfg.backend};
    baseUrl =
      if cfg.backend == "copilot" && hasCopilotApi then
        "127.0.0.1:${toString config.custom.copilot-api.port}"
      else
        "";
  in {
    assertions = [
      {
        assertion = cfg.backend != null;
        message = "custom.kilo.backend must be set when programs/kilo.nix is imported.";
      }
      {
        assertion = cfg.backend == null || selectedApiKey != null;
        message = "The API key for the selected Kilo backend must be set.";
      }
      {
        assertion = cfg.backend != "copilot" || hasCopilotApi;
        message = "The Copilot Kilo backend requires programs/copilot-api.nix to be imported.";
      }
    ];

    home.packages = [
      pkgs.kilo
    ];

    custom.chezmoi.templates.kilo = {
      enable = true;
      data = {
        base_url = builtins.toJSON baseUrl;
      };
      secrets = lib.optionalAttrs (selectedApiKey != null) {
        api_key = selectedApiKey;
      };
    };
  };
}
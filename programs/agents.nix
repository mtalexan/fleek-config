{ lib, config, ... }:
let
  cfg = config.custom.agents;
  ageKeys = config.custom.chezmoi.config.age_keys;

  # Chezmoi only lists a key class in chezmoi.toml when both fields are set,
  # and native encrypted_ files are decrypted with those identities.
  keyReady = class:
    ageKeys ? ${class}
    && ageKeys.${class}.secret_file != null
    && ageKeys.${class}.recipient != null;
in {
  options.custom.agents = with lib; {
    work = mkEnableOption ''
      chezmoi management of ~/.agents/skills/work.
      Files use chezmoi's native encrypted_ attribute and are decrypted with
      the work age key class (fleek_chezmoi_work).
    '';

    personal = mkEnableOption ''
      chezmoi management of ~/.agents/skills/personal.
      Files use chezmoi's native encrypted_ attribute and are decrypted with
      the personal age key class (fleek_chezmoi_personal).
    '';

    common = mkEnableOption ''
      chezmoi management of ~/.agents/skills/common.
      Files in this tree are stored and applied unencrypted.
    '';
  };

  config = {
    assertions = [
      {
        assertion = !cfg.work || keyReady "work";
        message = ''
          custom.agents.work requires custom.chezmoi.config.age_keys.work.secret_file
          and recipient (the fleek_chezmoi_work identity).
        '';
      }
      {
        assertion = !cfg.personal || keyReady "personal";
        message = ''
          custom.agents.personal requires custom.chezmoi.config.age_keys.personal.secret_file
          and recipient (the fleek_chezmoi_personal identity).
        '';
      }
    ];

    # .agents.enable / .agents.work / .agents.personal / .agents.common in templates.
    custom.chezmoi.templates.agents = {
      enable = cfg.work || cfg.personal || cfg.common;
      data = {
        work = cfg.work;
        personal = cfg.personal;
        common = cfg.common;
      };
    };
  };
}

# vim: ts=2:sw=2:expandtab

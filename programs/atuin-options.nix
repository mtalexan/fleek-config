{ lib, ... }: {
  options.custom.atuin = with lib; {
    ai = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the AI features of atuin.
      '';
    };
  };
}
{ lib, ... }: {
  options.custom.kilo = with lib; {
    backend = mkOption {
      type = types.nullOr (types.enum [ "copilot" ]);
      default = null;
      description = ''
        Backend to use for Kilo.
        The "copilot" backend requires the copilot-api module since it requires a gateway.
      '';
    };

    api_keys = {
      # NOTE: The structure of these options is being mapped exactly to the custom.chezmoi.templates.kilo.secrets structure, so the format and
      #       naming of the sub-options needs to match with custom.chezmoi.templates.*.secrets format.

      copilot = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            keyClass = mkOption {
              type = types.str;
              description = "Chezmoi age keyClass used to decrypt the Copilot API key. See the README.md for Chezmoi secrets.";
            };
            encryptedFile = mkOption {
              type = types.str;
              default = "copilot.age";
              description = "Filename in chezmoi/.chezmoisecrets/kilo/ containing the secret that's age-encrypted with the keyClass.";
            };
          };
        });
        default = null;
        description = ''
          Chezmoi secret specification for the Copilot API key.
        '';
      };
    };
  };
}
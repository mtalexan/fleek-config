{ pkgs, misc, lib, config, options, ... }: {
  # Chezmoi integration for home-manager.
  # Provides options for registering per-program template configuration (enable, data, secrets).
  # Generates ~/.config/chezmoi/chezmoi.toml and runs `chezmoi apply` as an activation script.

  config = let
    # Always include pkgs.age (needed for secret decryption) plus any additional
    # packages contributed by program modules via custom.chezmoi.config.apply_pkgs.
    allApplyPkgs = [ pkgs.age ] ++ config.custom.chezmoi.config.apply_pkgs;
  in {
    # Validate that every keyClass referenced by a secret is defined in
    # custom.chezmoi.config.age_keys and has both secret_file and recipient set.
    assertions = let
      allSecretRefs = lib.concatLists (lib.mapAttrsToList (program: cfg:
        lib.mapAttrsToList (secretName: s: {
          inherit program secretName;
          keyClass = s.keyClass;
        }) cfg.secrets
      ) config.custom.chezmoi.templates);
      ageKeys = config.custom.chezmoi.config.age_keys;
      definedKeyClasses = lib.attrNames ageKeys;
      # A key class is complete only when both secret_file and recipient are non-null.
      isComplete = kc: builtins.hasAttr kc ageKeys
        && ageKeys.${kc}.secret_file != null
        && ageKeys.${kc}.recipient != null;
      mkMessage = ref:
        if !(builtins.hasAttr ref.keyClass ageKeys) then
          "custom.chezmoi.templates.${ref.program}.secrets.${ref.secretName}.keyClass "
          + "references '${ref.keyClass}' which is not defined in custom.chezmoi.config.age_keys. "
          + "Defined key classes: ${lib.concatStringsSep ", " definedKeyClasses}"
        else
          let
            kc = ageKeys.${ref.keyClass};
            missing = (lib.optional (kc.secret_file == null) "secret_file")
              ++ (lib.optional (kc.recipient == null) "recipient");
          in
          "custom.chezmoi.templates.${ref.program}.secrets.${ref.secretName}.keyClass "
          + "references '${ref.keyClass}' which is missing required fields: "
          + "${lib.concatStringsSep ", " missing}. "
          + "Both secret_file and recipient must be set in custom.chezmoi.config.age_keys.${ref.keyClass}.";
    in map (ref: {
      assertion = isComplete ref.keyClass;
      message = mkMessage ref;
    }) allSecretRefs;

    home.packages = [
      pkgs.chezmoi
      # Only add to the allApplyPkgs since all extra tools need to be manually added to the PATH during chezmoiApply
    ] ++ allApplyPkgs;

    # Generate ~/.config/chezmoi/chezmoi.toml
    xdg.configFile."chezmoi/chezmoi.toml".source =
      let
        # Build per-program template data from the unified templates option.
        # Each program's template data is structured as:
        #   .<program>.enable = bool
        #   .<program>.<data_key> = value  (from templates.<program>.data.*)
        #   .<program>.secrets.<secret_name> = { file, identity }  (resolved from templates.<program>.secrets)
        chezmoiData = lib.mapAttrs (program: cfg: {
          enable = cfg.enable;
        } // cfg.data // {
          secrets = lib.mapAttrs (name: s: {
            file = "${config.custom.configdir}/chezmoi/.chezmoisecrets/${program}/${s.encryptedFile}";
            identity = config.custom.chezmoi.config.age_keys.${s.keyClass}.secret_file;
          }) cfg.secrets;
        }) config.custom.chezmoi.templates;

        tomlFormat = pkgs.formats.toml {};
        configFile = tomlFormat.generate "chezmoi.toml" ({
          encryption = "age";
          sourceDir = "${config.custom.configdir}/chezmoi";
          data = chezmoiData;
          age = let
            # Only include key classes where both secret_file and recipient are non-null.
            completeKeys = lib.filterAttrs (_: v: v.secret_file != null && v.recipient != null) config.custom.chezmoi.config.age_keys;
            # Strip optional trailing comment (e.g. user@host) from SSH public key recipients;
            # age is sensitive to it. Age-native recipients (age1...) are single tokens and unaffected.
            sanitizeRecipient = r: lib.concatStringsSep " " (lib.take 2 (lib.splitString " " r));
          in {
            command = "${pkgs.age}/bin/age";
            identities = lib.mapAttrsToList (_: v: v.secret_file) completeKeys;
            recipients = lib.mapAttrsToList (_: v: sanitizeRecipient v.recipient) completeKeys;
          };
        } // lib.optionalAttrs (config.custom.chezmoi.config.merge_tool != null) {
          merge = {
            command = config.custom.chezmoi.config.merge_tool;
            args = ["-d" "{{ .Destination }}" "{{ .Source }}" "{{ .Target }}"];
          };
        });
      in configFile;

    # Run chezmoi apply after all other home-manager file operations.
    # Prepend bin dirs from apply_pkgs so chezmoi templates can find them.
    home.activation.chezmoiApply =
      let
        applyPath = lib.concatMapStringsSep ":" (p: "${p}/bin") allApplyPkgs;
      in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "${config.custom.configdir}/chezmoi" ]; then
          set -o pipefail
          PATH="${applyPath}:$PATH" \
          ${pkgs.chezmoi}/bin/chezmoi apply \
            --no-tty \
            --force \
            2>&1 | head -50 || {
            echo ""
            echo "╔══════════════════════════════════════════════════════════════╗"
            echo "║  WARNING: chezmoi apply FAILED                              ║"
            echo "╠══════════════════════════════════════════════════════════════╣"
            echo "║  Your home-manager activation completed, but chezmoi        ║"
            echo "║  failed to apply dotfiles. Run 'chezmoi apply -v' manually  ║"
            echo "║  to diagnose the issue.                                     ║"
            echo "╚══════════════════════════════════════════════════════════════╝"
          }
          set +o pipefail
        fi
      '';
  };
}

# vim: ts=2:sw=2:expandtab

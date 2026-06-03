{ pkgs, misc, lib, config, options, ... }: {
  # Chezmoi integration for home-manager.
  # Provides options for registering per-program template configuration (enable, data, secrets).
  # Generates ~/.config/chezmoi/chezmoi.toml and runs `chezmoi apply` as an activation script.

  options.custom.chezmoi = with lib; {
    config = {
      merge_tool = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional custom 3-way merge tool for chezmoi to use when running 'chezmoi merge'.
          Must be an absolute path starting with /.
          If null, chezmoi uses its built-in diffing and merging logic.
        '';
      };

      apply_pkgs = mkOption {
        type = types.listOf types.package;
        default = [];
        description = ''
          Additional packages needed for generating the chezmoi config (i.e. 'chezmoi apply').
          These are nixpkgs needed during chezmoi template parsing in order to resolve
          the templates themselves. They are automatically added to home.packages as well.
          pkgs.age is always included automatically since it is called as part of the
          template resolution to insert decrypted secrets into the generated config files
          from age encrypted input files.
        '';
        example = lib.literalExpression "[ pkgs.sops ]";
      };

      # Named age key classes (identity + recipient) available on this host.
      age_keys = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            secret_file = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Absolute path to the private (identity) key file on this host.
              '';
            };
            recipient = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The age public key (recipient) corresponding to this identity,
                or the SSH public key file contents corresponding to this identity.
                Obtain with: 
                  age-keygen -y <path-to-private-key> 
                or
                  cat ~/<path-to-pubic-key-file>

                Note that this is allowed to include the optional name of the key that
                may appear as a 3rd value in the SSH public key file.
              '';
            };
          };
        }));
        default = {};
        description = ''
          Named classes of age keys available on this host.
          Maps a class name (e.g. "work", "personal") to a key specification
          containing the identity file path and the corresponding recipient
          public key string. Programs reference these by class name when
          registering secrets.
          The collected set of these identities and recipients are also included
          in the chezmoi.toml file, allowing them to be used directly with the
          'decrypt' built-in template function and/or with encrypted_* files,
          though there is no traceability in that case for which key is used for
          which artifacts, nor build-time enforcement.
        '';
        example = {
          work = { 
            secret_file = "/home/user/.age/fleek_agecrypt"; 
            recipient = "age1..."; 
          };
          personal = { 
            secret_file = "/home/user/.ssh/personal_age_encryption_key"; 
            recipient = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAA"; 
          };
        };
      };
    };
    
    templates = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether this program's chezmoi-managed files are active on this host.
              Controls the .chezmoiignore.tmpl: when false, chezmoi ignores the
              program's files. Exposed in templates as .<program>.enable.
            '';
          };

          data = mkOption {
            type = types.attrsOf types.anything;
            default = {};
            description = ''
              Non-secret template data for this program.
              Ends up in the nix store, so do NOT put secrets here.
              Exposed in templates as .<program>.<key> (i.e. data keys are
              lifted to be siblings of .enable and .secrets).
            '';
          };

          secrets = mkOption {
            type = types.attrsOf (types.submodule ({ name, ... }: {
              options = {
                encryptedFile = mkOption {
                  type = types.str;
                  default = "${name}.age";
                  description = ''
                    Filename of the .age file within chezmoi/.chezmoisecrets/<program>/.
                    Defaults to <secret_name>.age based on the attribute name.
                  '';
                };
                keyClass = mkOption {
                  type = types.str;
                  description = ''
                    Name of the age key class (from custom.chezmoi.config.age_keys) that
                    can decrypt this secret.
                  '';
                };
              };
            }));
            default = {};
            description = ''
              Secrets available to chezmoi templates for this program.
              Structure: templates.<program>.secrets.<secret_name> = { keyClass, encryptedFile? }
              File convention: chezmoi/.chezmoisecrets/<program>/<encryptedFile>
              Exposed in templates as: .<program>.secrets.<secret_name>
              The chezmoi module resolves keyClass to actual identity path at evaluation time.
            '';
            example = {
              gitlab_pat = {
                keyClass = "work";
                # encryptedFile defaults to "gitlab_pat.age" if not otherwise specified.
                encryptedFile = "foo-bar.age";
              };
            };
          };
        };
      }));
      default = {};
      description = ''
        Per-program chezmoi template configuration.
        Each key is a program name. The submodule provides:
          - enable: controls .chezmoiignore.tmpl (whether chezmoi manages this program's files)
          - data: non-secret template data (exposed as .<program>.<key>)
          - secrets: age-encrypted secrets (exposed as .<program>.secrets.<secret_name>)
      '';
      example = {
        zed = {
          enable = true;
          data = {
            copilot = true;
            gitlab_mcp = true;
          };
          secrets = {
            gitlab_pat = {
              keyClass = "work";
            };
          };
        };
      };
    };
  };

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

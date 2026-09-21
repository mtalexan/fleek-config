{ lib, ... }: {
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
}
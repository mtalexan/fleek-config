{ pkgs, misc, lib, config, ... }: {
  # Zed editor configuration, managed via chezmoi templates.
  #
  # The Zed config files live in chezmoi/dot_config/zed/ and are applied by chezmoi
  # to ~/.config/zed/ at home-manager activation time.
  #
  # Zed suffers from similar issues to VSCode, in that the language servers and extra data
  # it downloads for extensions don't work properly when Zed is a nix package.
  #
  # The Zed flake overlay has pkgs.zed-editor in it, but that's updated nightly and tends to be pretty unstable.
  # It used to be that that was the only way to get an FHS that would allow installing extensions from an external source,
  # but now the nixpkgs:unstable has zed-editor-fhs that's based on the weekly stable releases.

  options.custom.zed = with lib; {
    gitlab_mcp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the GitLab MCP context server block in Zed settings.
          When true, requires:
            - custom.chezmoi.config.age_keys to include the "work" class
            - custom.zed.gitlab_mcp.url to be set (in hosts/ file)
        '';
      };
      url = mkOption {
        type = types.str;
        default = "";
        description = ''
          GitLab API URL for the MCP context server.
          This is private (should only appear in git-agecrypt encrypted hosts/ files)
          but is not a secret (fine to be on the target system in chezmoi.toml).
        '';
      };
    };
    copilot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Copilot as the edit_predictions provider and copilot_chat
        as the default agent model provider in Zed settings.
        When false, these blocks are omitted entirely (Zed uses its own defaults).
      '';
    };
  };

  config = {
    # Packages zed needs to have externally installed.
    home.packages = [
      # Nix language server has to be manually installed external to zed.
      # Install both even though only one usually gets used.
      pkgs.nixd
      pkgs.nil
      # needed by Basher extension
      pkgs.shellcheck
      # Use the one from a separate flake, which is configured in the main flake.nix.
      pkgs.zed-independent
    ];

    # Register zed with chezmoi for conditional file management and template data
    custom.chezmoi.templates.zed = {
      enable = true;

      # Map custom.zed.* options → chezmoi template data under [data.zed]
      data = {
        gitlab_mcp = config.custom.zed.gitlab_mcp.enable;
        gitlab_api_url = config.custom.zed.gitlab_mcp.url;
        copilot = config.custom.zed.copilot;
      };

      secrets = lib.mkIf config.custom.zed.gitlab_mcp.enable {
        # accessed in templates as .zed.secrets.gitlab_pat
        gitlab_pat = {
          # default value for 'encryptedFile' name is "gitlab_pat.age".
          # Age-encrypted secret is therefore in chezmoi/.chezmoisecrets/zed/gitlab_pat.age.
          #
          # Use "work" key class, which maps to the custom.chezmoi.config.age_keys.work key file specified by the hosts/*.nix file.
          keyClass = "work";
        };
      };
    };
  };
}

# vim: ts=2:sw=2:expandtab

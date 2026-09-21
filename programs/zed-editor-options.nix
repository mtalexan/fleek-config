{ lib, ... }: {
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
    broken_wgpu = mkOption {
      type = types.nullOr (types.enum [ "nvidia" "sw" ]);
      default = null;
      description = ''
        Workaround for Zed's wgpu backend breaking common Intel iGPUs.
        See: https://github.com/zed-industries/zed/issues/52517

        - null:     No workaround applied. Use this when the iGPU is not present
                    or the wgpu bug does not affect this host.
        - "nvidia": Force Zed to use the NVIDIA dGPU's Vulkan ICD, bypassing the
                    broken Intel driver. Requires an NVIDIA dGPU and sets
                    VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json.
        - "sw":     Force software (llvmpipe) rendering via the lavapipe ICD.
                    Use this when no working dGPU is available. Slower, but functional.
      '';
    };
  };
}
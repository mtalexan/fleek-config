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

  config = let
      # Use the one from a separate flake, which is configured in the main flake.nix.
      zed_base = pkgs.zed-independent;
  
      wrapperArgs = {
        nvidia = [ "--set" "VK_ICD_FILENAMES" "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json" ];
        sw     = [ "--set" "VK_ICD_FILENAMES" "/usr/share/vulkan/icd.d/lvp_icd.x86_64.json" ];
      };
  
      zedPkg =
        if config.custom.zed.broken_wgpu != null
        then
          pkgs.symlinkJoin {
            name = "zed-wrapped";
            paths = [ zed_base ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/zeditor \
                ${lib.concatStringsSep " \\\n              " wrapperArgs.${config.custom.zed.broken_wgpu}}
            '';
          }
        else zed_base;
    in {
    # Packages zed needs to have externally installed.
    home.packages = [
      # Nix language server has to be manually installed external to zed.
      # Install both even though only one usually gets used.
      pkgs.nixd
      pkgs.nil
      # needed by Basher extension
      pkgs.shellcheck
      # defined in the let block
      zedPkg
    ];

    # Register zed with chezmoi for conditional file management and template data
    custom.chezmoi.templates.zed = {
      enable = true;

      # Map custom.zed.* options → chezmoi template data under [data.zed]
      data = {
        gitlab_mcp = config.custom.zed.gitlab_mcp.enable;
        gitlab_api_url = config.custom.zed.gitlab_mcp.url;
        copilot = config.custom.zed.copilot;
        # Defines the command to run for the task we've custom bound to Ctrl+P for file search since zed's built-in file search has so many problems.
        # We're basically running an fd search in fzf to pick files to open in the current zed window.
        # The regular 'fd ... | fzf ...' works poorly on very large directories because it basically writes every file in existence to fzf to fuzzy filter.
        # Instead we set the fd command to run as a '--bind change:reload' event, which means fzf will kick off a new fd on each typed query update.
        # fd normally only allows regex patterns, but to keep fuzzy filtering we end up filtering the results with fzf as well. 
        # This won't work for all patterns, but it will for most as long as the special fzf search characters aren't used. Space-separated words are 
        # treated as separate regexes to fd to take out the bulk of hits, and fzf filters down what's left.
        # 
        # Don't follow .gitignore, it breaks git externals.
        # Need to force color output from fd.
        # The usual Ctrl+/ for toggling preview conflicts, so custom bind in fzf to Alt+/.
        # Start preview window hidden by default, and use the fzf-defined file preview program.
        # Use 'zeditor -e' to force opening in the currently active window. 
        # Do NOT use ${pkgs.zeditor}/bin/zeditor, we don't want to hardcode the task file to our specific zeditor verison.
        # WARNING: This gets inserted into a JSON string, so it cannot contain " characters
        fileSearchCmd = "fd --type f --no-ignore-vcs --hidden --exclude '.git' --follow --strip-cwd-prefix --color=always | fzf --height=100% --multi --preview '${config.custom.fzf.filePreviewCmd}' --preview-window='right:50%:hidden' | xargs -r -d '\\n' zeditor -e";
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

{ pkgs, lib, config, fleekConfigName, ... }:
let
  editorSync = pkgs.callPackage ./package.nix {};
in {
  options.custom.editorSync = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = editorSync;
      description = "Nix store package for the editor-sync tool.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.toLower fleekConfigName;
      description = "Lowercased user@host home-manager configuration name; selects chezmoi/.editor-config/hosts/<host>/.";
    };
  };

  config = {
    home.packages = [ editorSync ];
    custom.chezmoi.config.apply_pkgs = [ editorSync ];
    custom.chezmoi.templates.editor_sync.data.host = config.custom.editorSync.host;

    # bash enableCompletion does not load profile completions on its own here.
    programs.bash.initExtra = ''
      if [[ -r ${editorSync}/share/bash-completion/completions/editor-sync ]]; then
        source ${editorSync}/share/bash-completion/completions/editor-sync
      fi
    '';

    # fpath must be set before compinit, which completionInit runs at order 550.
    programs.zsh.initContent = lib.mkOrder 550 ''
      fpath=(${editorSync}/share/zsh/site-functions $fpath)
    '';
  };
}

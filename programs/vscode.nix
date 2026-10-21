{ pkgs, misc, lib, config, ... }:
let
  # There's an open bug in nixpkgs for VSCode that loses the executable permission for the copilot-runtime.
  # There's a PR fix: https://github.com/NixOS/nixpkgs/pull/573515/files
  # Until the PR is merged, we just manually fix it here.
  vscodePackage = pkgs.vscode-independent.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      copilotDir="$out/lib/vscode/resources/app/node_modules.asar.unpacked/@github"
      if [ -d "$copilotDir" ]; then
        find "$copilotDir" -type f -name copilot-runtime -exec chmod a+x {} +
      fi
    '';
  });
in {
  imports = [ ./editor-sync ];

  # already includes it's own *.desktop entry file, you just have to restart the gnome session to get it to show up

  # Do NOT use the home-manager settings. It installs its own config that prevents the settings from being synced or modified in the GUI.
  # Instead, install only the package.  This still has the program and the desktop files, but doesn't try to manage the settings files.
  home.packages = [
    # use the one from a separate flake so we can update it separately. Which package it actually ends up being is set in the flake.nix
    vscodePackage
  ];

  #programs.vscode = {
  #  enable = true;
  #  enableExtensionUpdateCheck = true;
  #  # it always says it's out of date, disable it
  #  enableUpdateCheck = false;
  #  # could be vscodium, or something else. There are a few options
  #  package = pkgs.vscode;
  #
  #  #extensions = [];
  #  #globalSnippets = {};
  #  #keybindings = [];
  #  #languageSnippets = {};
  #
  #  # allow extensions to be installed and managed separately
  #  mutableExtensionsDir = true;
  #
  #  #userSettings = {};
  #  #userTasks = {};
  #};

  custom.chezmoi.templates.vscode.enable = true;

  # After chezmoiApply has rendered settings. Missing extensions.json skips; failures warn.
  home.activation.editorSyncVscodeExtensions = lib.hm.dag.entryAfter [ "chezmoiApply" ] ''
    if ! ${config.custom.editorSync.package}/bin/editor-sync extensions-sync \
        --source ${config.custom.configdir}/chezmoi/.editor-config \
        --host ${lib.escapeShellArg config.custom.editorSync.host} \
        vscode ${vscodePackage}/bin/code
    then
      echo ""
      echo "╔══════════════════════════════════════════════════════════════╗"
      echo "║  WARNING: VS Code extension sync FAILED                     ║"
      echo "╠══════════════════════════════════════════════════════════════╣"
      echo "║  Your home-manager activation completed, but editor-sync    ║"
      echo "║  failed to install or uninstall VS Code extensions. Run     ║"
      echo "║  'editor-sync extensions-sync' manually to diagnose.        ║"
      echo "╚══════════════════════════════════════════════════════════════╝"
    fi
  '';
}

# vim: ts=2:sw=2:expandtab

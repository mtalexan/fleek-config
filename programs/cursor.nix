{ pkgs, misc, lib, config, ... }:
let
  cfg = config.custom.cursor;
  xpraDisplay = ":${toString config.custom.xpra.display}";
  cursor = lib.getExe' pkgs.code-cursor-independent "cursor";
  cursorXpra = pkgs.writeShellApplication {
    name = "cursor-xpra";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
      pkgs.util-linux
      pkgs.xpra
    ];
    text = ''
      xpra_display=${lib.escapeShellArg xpraDisplay}
      current_display="''${DISPLAY:-}"

      if [[ "$current_display" = "$xpra_display" || "$current_display" = "$xpra_display.0" ]]; then
        exec env DISPLAY="$xpra_display" ELECTRON_OZONE_PLATFORM_HINT=x11 \
          ${cursor} --disable-gpu "$@"
      fi

      systemctl --user start xpra.service

      server_ready=false
      for _ in {1..100}; do
        if xpra info "$xpra_display" >/dev/null 2>&1; then
          server_ready=true
          break
        fi
        sleep 0.1
      done
      if [[ "$server_ready" != true ]]; then
        echo "Xpra server $xpra_display did not become ready" >&2
        exit 1
      fi

      runtime_dir="''${XDG_RUNTIME_DIR:-/tmp/cursor-xpra-$UID}"
      install -d -m 700 "$runtime_dir"
      log_file="$runtime_dir/cursor-xpra-${toString config.custom.xpra.display}.log"

      # The desktop session XAUTHORITY has no cookie for the Xpra display.
      env DISPLAY="$xpra_display" XAUTHORITY="$HOME/.Xauthority" \
        ELECTRON_OZONE_PLATFORM_HINT=x11 \
        ${cursor} --disable-gpu "$@" >"$log_file" 2>&1 &

      seat="''${WAYLAND_DISPLAY:-}:''${DISPLAY:-}"
      seat_hash="$(printf '%s' "$seat" | sha256sum | cut -d ' ' -f 1)"
      lock_file="$runtime_dir/cursor-xpra-${toString config.custom.xpra.display}-$seat_hash.lock"

      exec 9>"$lock_file"
      if ! flock --nonblock 9; then
        echo "An Xpra client for $xpra_display is already attached to this display. Cursor log: $log_file" >&2
        exit 0
      fi

      exec xpra attach "$xpra_display" --sharing=yes
    '';
  };

  # Local copies take precedence over the package launchers. They exist only
  # while wrapping is enabled, and only the cursor command on each Exec line changes.
  patchCursorDesktop = name: pkgs.runCommand name { } ''
    sed -e 's|^Exec=cursor\([[:space:]]\)|Exec=${lib.getExe cursorXpra}\1|' \
      ${pkgs.code-cursor-independent}/share/applications/${name} > "$out"
  '';

  cursorRemote = pkgs.writeShellApplication {
    name = "cursor-remote";
    runtimeInputs = [ pkgs.xpra ];
    text = ''
      display=${toString config.custom.xpra.display}
      server=

      usage() {
        printf 'Usage: cursor-remote [--display=NUMBER] SERVER\n' >&2
        exit 1
      }

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --display=*)
            display="''${1#--display=}"
            ;;
          --display)
            shift
            [[ $# -gt 0 ]] || usage
            display="$1"
            ;;
          -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage
            ;;
          *)
            [[ -z "$server" ]] || usage
            server="$1"
            ;;
        esac
        shift
      done

      [[ -n "$server" ]] || usage
      if [[ ! "$display" =~ ^[0-9]+$ ]]; then
        printf 'Display must be a number, got: %s\n' "$display" >&2
        exit 1
      fi

      exec xpra attach --ssh=ssh --sharing=yes "ssh://''${server}/''${display}"
    '';
  };
in {
  imports = [ ./editor-sync ];

  assertions = lib.optionals cfg.xpra [{
    assertion = config.custom.xpra.enable;
    message = "custom.cursor.xpra requires custom.xpra.enable.";
  }];

  ## Stop hook for notifying on Linux when attention is needed.

  # File is a nix-store symlink; ~/.cursor and ~/.cursor/hooks are created as user-owned dirs.
  home.file.".cursor/hooks/notify-on-stop.sh" = {
    source = ./cursor/hooks/notify-on-stop.sh;
    executable = true;
  };

  # User-level hooks run with cwd ~/.cursor/. mkOrder 1500 so this runs after default-priority stop hooks.
  custom.cursor.hooks.stop = lib.mkOrder 1500 [{
    command = "./hooks/notify-on-stop.sh";
    timeout = 10;
  }];

  #----------------------------------------------------------------------------------------------------

  # already includes it's own *.desktop entry file, you just have to restart the gnome session to get it to show up

  # Do NOT use the home-manager settings. It installs its own config that prevents the settings from being synced or modified in the GUI.
  # Instead, install only the package.  This still has the program and the desktop files, but doesn't try to manage the settings files.
  home.packages = [
    # use the one from a separate flake so we can update it separately. Which package it actually ends up being is set in the flake.nix
    pkgs.code-cursor-independent
    pkgs.cursor-cli-independent
    # needed by notify-on-stop.sh
    pkgs.libnotify
  ] ++ lib.optionals cfg.remote [
    cursorRemote
  ];

  programs.bash.shellAliases = lib.mkIf cfg.xpra {
    cursor = lib.getExe cursorXpra;
  };

  programs.zsh.shellAliases = lib.mkIf cfg.xpra {
    cursor = lib.getExe cursorXpra;
  };

  xdg.dataFile."applications/cursor.desktop" = lib.mkIf cfg.xpra {
    source = patchCursorDesktop "cursor.desktop";
  };
  xdg.dataFile."applications/cursor-url-handler.desktop" = lib.mkIf cfg.xpra {
    source = patchCursorDesktop "cursor-url-handler.desktop";
  };

  custom.chezmoi.templates.cursor = {
    enable = true;
    data = {
      # Nix JSON conversion; omit empty hook types. Avoids TOML round-trip of nested lists.
      hooks = builtins.toJSON (
        lib.filterAttrs (_: v: v != []) config.custom.cursor.hooks
      );
    };
  };

  #programs.cursor = {
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

  # After chezmoiApply has rendered settings. Missing extensions.json skips; failures warn.
  home.activation.editorSyncCursorExtensions = lib.hm.dag.entryAfter [ "chezmoiApply" ] ''
    if ! ${config.custom.editorSync.package}/bin/editor-sync extensions-sync \
        --source ${config.custom.configdir}/chezmoi/.editor-config \
        --host ${lib.escapeShellArg config.custom.editorSync.host} \
        cursor ${pkgs.code-cursor-independent}/bin/cursor
    then
      echo ""
      echo "╔══════════════════════════════════════════════════════════════╗"
      echo "║  WARNING: Cursor extension sync FAILED                      ║"
      echo "╠══════════════════════════════════════════════════════════════╣"
      echo "║  Your home-manager activation completed, but editor-sync    ║"
      echo "║  failed to install or uninstall Cursor extensions. Run      ║"
      echo "║  'editor-sync extensions-sync' manually to diagnose.        ║"
      echo "╚══════════════════════════════════════════════════════════════╝"
    fi
  '';
}

# vim: ts=2:sw=2:expandtab

{ pkgs, lib, inputs, config, herdrPlugins ? null, ... }:
# Import this module directly from each program that needs Plannotator available.
let
  upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.plannotator;
  useTerminalBrowser = config.custom.herdr.plannotator.terminalBrowser.enable;

  # Only forced when the in-terminal opener is enabled, so other hosts do not build terminal-browser.
  herdrBin = lib.getExe config.programs.herdr.package;
  terminalBrowserBin =
    if herdrPlugins == null
    then throw "plannotator: herdrPlugins is required when custom.herdr.plannotator.terminalBrowser.enable is true"
    else lib.getExe herdrPlugins.herdr-terminal-browser.passthru.terminal-browser-bin;
  jqBin = lib.getExe pkgs.jq;
  curlBin = lib.getExe pkgs.curl;
  setsidBin = lib.getExe' pkgs.util-linux "setsid";
  flockBin = lib.getExe' pkgs.util-linux "flock";

  # Opens a URL through the XDG desktop portal over the session D-Bus, falling back to xdg-open.
  # The portal runs in the desktop session, so this works even when DISPLAY/XAUTHORITY are stale.
  # That happens in panes of a long-running herdr server started before the session's X display settled.
  # Plannotator would otherwise keep the stale DISPLAY/XAUTHORITY from that server.
  #
  # When the herdr terminal-browser option is on and this runs inside a herdr pane, open the review
  # in that workspace's terminal-browser instead. Plannotator spawns this with the URL as argv and
  # stdio ignored, so every tool path is absolute.
  # Plannotator's auto-close setting only calls window.close(). terminal-browser does not drop the
  # tab on that event, so a detached watcher closes the browser tab when the review server stops.
  openUrl = pkgs.writeShellApplication {
    name = "plannotator-open-url";
    runtimeInputs = [
      pkgs.glib
      pkgs.xdg-utils
      pkgs.coreutils
    ] ++ lib.optionals useTerminalBrowser [
      config.programs.herdr.package
      herdrPlugins.herdr-terminal-browser.passthru.terminal-browser-bin
      pkgs.jq
      pkgs.curl
      pkgs.util-linux
    ];
    text = ''
      fallback_open() {
        if gdbus call --session --timeout 5 \
            --dest org.freedesktop.portal.Desktop \
            --object-path /org/freedesktop/portal/desktop \
            --method org.freedesktop.portal.OpenURI.OpenURI \
            "" "$1" "{}" >/dev/null 2>&1; then
          exit 0
        fi
        exec xdg-open "$1"
      }
    '' + lib.optionalString useTerminalBrowser ''
      curl_up() {
        ${curlBin} --silent --output /dev/null --max-time 2 --connect-timeout 2 "$1"
      }

      browser_alive() {
        local json
        if ! json=$(${terminalBrowserBin} ls --all --json 2>/dev/null); then
          return 1
        fi
        ${jqBin} -e --arg k "$1" '[.browsers[]? | select(.key == $k)] | length > 0' >/dev/null <<<"$json"
      }

      # Closing the last terminal-browser tab shuts that process down. Open a blank
      # tab first in that case so the process and herdr tab stay for the next review.
      # Closes for one browser are serialized so two finishing reviews cannot both
      # close the last tab.
      close_review_tab() {
        local key="$1"
        local tab="$2"
        local lockdir json others
        lockdir="''${XDG_RUNTIME_DIR:-/tmp}/plannotator-review-locks"
        mkdir -p "$lockdir" || return 0
        (
          ${flockBin} -w 30 9 || exit 0
          if ! json=$(${terminalBrowserBin} ls --all --json 2>/dev/null); then
            exit 0
          fi
          if ! ${jqBin} -e --arg k "$key" --argjson id "$tab" 'any(.browsers[]?; .key == $k and any(.tabs[]?; .id == $id))' >/dev/null <<<"$json"; then
            exit 0
          fi
          others=$(${jqBin} -r --arg k "$key" --argjson id "$tab" '[.browsers[]? | select(.key == $k) | .tabs[]? | select(.id != $id)] | length' <<<"$json") || exit 0
          if [[ "$others" == "0" ]]; then
            ${terminalBrowserBin} new-tab --browser "$key" >/dev/null 2>&1 || exit 0
          fi
          ${terminalBrowserBin} action --browser "$key" -- tab close "$tab" >/dev/null 2>&1 || true
        ) 9>"$lockdir/$key.lock" || true
      }

      watch_review() {
        local url="$1"
        local key="$2"
        local tab="$3"
        local seen=0
        local misses=0
        local deadline=$((SECONDS + 7200))

        if [[ -z "$url" || -z "$key" || -z "$tab" ]]; then
          return 0
        fi

        while (( SECONDS < deadline )); do
          if ! browser_alive "$key"; then
            return 0
          fi
          if curl_up "$url"; then
            seen=1
            misses=0
          elif [[ "$seen" == 1 ]]; then
            misses=$((misses + 1))
            if (( misses >= 2 )); then
              close_review_tab "$key" "$tab"
              return 0
            fi
          fi
          sleep 2
        done
      }

      start_watch() {
        ${setsidBin} "$0" --watch "$1" "$2" "$3" </dev/null >/dev/null 2>&1 &
      }

      wait_for_shell() {
        local pane="$1"
        local i=0
        local info shell_pid fg_pid
        while (( i < 75 )); do
          i=$((i + 1))
          if info=$(${herdrBin} pane process-info --pane "$pane" 2>/dev/null); then
            shell_pid=$(${jqBin} -r '.result.process_info.shell_pid // empty' <<<"$info")
            fg_pid=$(${jqBin} -r '.result.process_info.foreground_processes[0].pid // empty' <<<"$info")
            if [[ -n "$shell_pid" && "$fg_pid" == "$shell_pid" ]]; then
              return 0
            fi
          fi
          sleep 0.2
        done
        return 1
      }

      close_tab() {
        ${herdrBin} tab close "$1" >/dev/null 2>&1 || true
      }

      open_in_herdr() {
        local url="$1"
        local ws=""
        local browser_json=""
        local key=""
        local tab_id=""
        local herdr_tab=""
        local opened=""
        local created=""
        local new_tab=""
        local new_pane=""
        local found_key=""
        local found_tab=""
        local cmd=""
        local i=0
        local cand_key=""
        local cand_pane=""
        local cand_ws=""

        ws="''${HERDR_WORKSPACE_ID:-}"
        if [[ -z "$ws" ]]; then
          if ! ws=$(${herdrBin} pane get "''${HERDR_PANE_ID:-}" | ${jqBin} -r '.result.pane.workspace_id // empty'); then
            return 1
          fi
        fi
        if [[ -z "$ws" ]]; then
          return 1
        fi

        # Reuse only a browser whose pane is in this workspace.
        if browser_json=$(${terminalBrowserBin} ls --all --json 2>/dev/null); then
          while IFS=$'\t' read -r cand_key cand_pane; do
            [[ -z "$cand_key" || -z "$cand_pane" ]] && continue
            if ! cand_ws=$(${herdrBin} pane get "$cand_pane" 2>/dev/null | ${jqBin} -r '.result.pane.workspace_id // empty'); then
              continue
            fi
            if [[ "$cand_ws" == "$ws" ]]; then
              key="$cand_key"
              break
            fi
          done < <(${jqBin} -r '.browsers[]? | select(.pane.pane != null and .pane.pane != "") | [.key, .pane.pane] | @tsv' <<<"$browser_json")
        fi

        if [[ -n "$key" ]]; then
          if ! opened=$(${terminalBrowserBin} new-tab --browser "$key" "$url"); then
            return 1
          fi
          tab_id=$(${jqBin} -r '.openedTab // empty' <<<"$opened" 2>/dev/null || true)
          herdr_tab=$(${jqBin} -r --arg k "$key" 'first(.browsers[]? | select(.key == $k) | .pane.tab) // empty' <<<"$browser_json")
          if [[ -n "$herdr_tab" ]]; then
            ${herdrBin} tab focus "$herdr_tab" >/dev/null 2>&1 || true
          fi
          if [[ -n "$tab_id" ]]; then
            start_watch "$url" "$key" "$tab_id"
          fi
          return 0
        fi

        if ! created=$(${herdrBin} tab create --workspace "$ws" --label "Plannotator review" --focus --cwd "$PWD"); then
          return 1
        fi
        new_tab=$(${jqBin} -r '.result.tab.tab_id // empty' <<<"$created")
        new_pane=$(${jqBin} -r '.result.root_pane.pane_id // empty' <<<"$created")
        if [[ -z "$new_tab" || -z "$new_pane" ]]; then
          [[ -n "$new_tab" ]] && close_tab "$new_tab"
          return 1
        fi

        # pane run is lost if it arrives before the new tab's shell is reading.
        if ! wait_for_shell "$new_pane"; then
          close_tab "$new_tab"
          return 1
        fi
        sleep 1
        printf -v cmd '%s open --no-merge %q' ${lib.escapeShellArg terminalBrowserBin} "$url"
        if ! ${herdrBin} pane run "$new_pane" "$cmd"; then
          close_tab "$new_tab"
          return 1
        fi

        while (( i < 40 )); do
          i=$((i + 1))
          if browser_json=$(${terminalBrowserBin} ls --all --json 2>/dev/null); then
            found_key=$(${jqBin} -r --arg p "$new_pane" 'first(.browsers[]? | select(.pane.pane == $p) | .key) // empty' <<<"$browser_json")
            if [[ -n "$found_key" ]]; then
              found_tab=$(${jqBin} -r --arg p "$new_pane" 'first(.browsers[]? | select(.pane.pane == $p) | (.tabs[0].id // empty)) // empty' <<<"$browser_json")
              if [[ -n "$found_tab" ]]; then
                break
              fi
            fi
          fi
          sleep 0.5
        done
        if [[ -z "$found_key" || -z "$found_tab" ]]; then
          close_tab "$new_tab"
          return 1
        fi
        start_watch "$url" "$found_key" "$found_tab"
        return 0
      }

      if [[ "''${1:-}" == "--watch" ]]; then
        watch_review "''${2:-}" "''${3:-}" "''${4:-}"
        exit 0
      fi
    '' + ''
      url="''${1:-}"
      if [[ -z "$url" ]]; then
        echo "plannotator-open-url: missing url" >&2
        exit 1
      fi
    '' + lib.optionalString useTerminalBrowser ''
      if [[ "''${HERDR_ENV:-}" == "1" && -n "''${HERDR_PANE_ID:-}" ]]; then
        if open_in_herdr "$url"; then
          exit 0
        fi
      fi
    '' + ''
      fallback_open "$url"
    '';
  };

  # Copilot hooks run outside a login shell, so add the tools plannotator calls to its PATH.
  # A PLANNOTATOR_BROWSER set by the user still takes precedence over the portal opener.
  plannotator = pkgs.symlinkJoin {
    name = "plannotator-wrapped-${upstream.version}";
    paths = [ upstream ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "plannotator";
    postBuild = ''
      wrapProgram $out/bin/plannotator \
        --suffix PATH : ${lib.makeBinPath [ pkgs.git pkgs.openssh pkgs.xdg-utils ]} \
        --set-default PLANNOTATOR_BROWSER ${lib.getExe openUrl}
    '';
  };

  # The plannotator-copilot hook runs `$HOME/.local/bin/plannotator copilot-plan` before every tool call.
  # Plannotator only acts on exit_plan_mode, where it blocks until the browser review is submitted. Copilot
  # gives no sign it's waiting on the user, so send a desktop notification for that case first.
  # We have to replicate the filtering plannotator does so we can generate the notification for a review
  # being opened in the browser.
  hookWrapper = pkgs.writeShellApplication {
    name = "plannotator";
    runtimeInputs = [ pkgs.jq pkgs.libnotify pkgs.util-linux ];
    text = ''
      if [ "''${1:-}" != "copilot-plan" ]; then
        exec ${lib.getExe plannotator} "$@"
      fi

      input=$(cat)
      if [ "$(jq -r '.toolName // empty' <<<"$input" 2>/dev/null)" = "exit_plan_mode" ]; then
        project=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null || true)
        # Detached so a slow or missing notification daemon can't delay the review.
        setsid notify-send --app-name="GitHub Copilot" --icon=dialog-question \
          "Plan ready for review" "''${project:-$PWD}" >/dev/null 2>&1 </dev/null &
      fi
      exec ${lib.getExe plannotator} "$@" <<<"$input"
    '';
  };
in {
  options.custom.plannotator = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
      description = ''
        Install the wrapped Plannotator package, its Copilot hook wrapper, and the chezmoi config.
        Programs that use Plannotator set this. Hosts use custom.herdr.plannotator.enable.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = plannotator;
      description = "Wrapped Plannotator package. Adds the tools its hooks call to PATH and opens review URLs.";
    };
  };

  config = lib.mkIf config.custom.plannotator.enable {
    home.packages = [ plannotator ];

    custom.chezmoi.templates.plannotator.enable = true;

    # The plannotator-copilot plugin hook hardcodes $HOME/.local/bin/plannotator.
    home.file.".local/bin/plannotator".source = lib.getExe hookWrapper;
  };
}

# vim: ts=2:sw=2:expandtab

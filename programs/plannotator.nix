{ pkgs, lib, inputs, ... }:
# Import this module directly from each program that needs Plannotator available.
let
  upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.plannotator;

  # Opens a URL through the XDG desktop portal over the session D-Bus, falling back to xdg-open.
  # The portal runs in the desktop session, so this works even when DISPLAY/XAUTHORITY are stale.
  # That happens in panes of a long-running herdr server started before the session's X display settled.
  # Normally plannotator tries to directly use the DISPLAY/XAUTHORITY value instead of using xdg-open like
  # it should. The effect is that any changes to the default browser or display settings since the herdr
  # server started (assuming the plannotator call is from copilot running in herdr) will be ignored.
  openUrl = pkgs.writeShellApplication {
    name = "plannotator-open-url";
    runtimeInputs = [ pkgs.glib pkgs.xdg-utils ];
    text = ''
      url="$1"
      if gdbus call --session --timeout 5 \
          --dest org.freedesktop.portal.Desktop \
          --object-path /org/freedesktop/portal/desktop \
          --method org.freedesktop.portal.OpenURI.OpenURI \
          "" "$url" "{}" >/dev/null 2>&1; then
        exit 0
      fi
      exec xdg-open "$url"
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
in {
  options.custom.plannotator.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = plannotator;
    description = "Wrapped Plannotator package. Adds the tools its hooks call to PATH and opens URLs through the desktop portal.";
  };

  config = {
    home.packages = [ plannotator ];

    custom.chezmoi.templates.plannotator.enable = true;

    # The plannotator-copilot plugin hook hardcodes $HOME/.local/bin/plannotator.
    home.file.".local/bin/plannotator".source = "${plannotator}/bin/plannotator";
  };
}

# vim: ts=2:sw=2:expandtab

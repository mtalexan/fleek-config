{ lib, pkgs, config, ... }:
let
  cfg = config.custom.shared-mime-info;
  nixVersion = config.xdg.mime.sharedMimeInfoPackage.version;
in {
  config = lib.mkMerge [
    (lib.mkIf cfg.useStable {
      xdg.mime.sharedMimeInfoPackage = pkgs.shared-mime-info-stable;
    })

    # Runs before writeBoundary so a mismatch aborts before anything is changed.
    # If the shared-mime-info.useStable custom setting isn't enabled, run a check of the host system on activation
    # to make sure it has shared-mime-info >= 2.5.
    (lib.mkIf (config.xdg.mime.enable && !cfg.useStable && lib.versionAtLeast nixVersion "2.5") {
      home.activation.checkSharedMimeInfoHostVersion = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        hostMimeVersionFile=/usr/share/mime/version
        if [ -r "$hostMimeVersionFile" ]; then
          hostMimeVersion="$(head -n1 "$hostMimeVersionFile" | tr -d '[:space:]')"
          lowest="$(printf '%s\n%s\n' "$hostMimeVersion" "2.5" | sort -V | head -n1)"
          if [ -n "$hostMimeVersion" ] && [ "$lowest" = "$hostMimeVersion" ] && [ "$hostMimeVersion" != "2.5" ]; then
            errorEcho "Host shared-mime-info is $hostMimeVersion ($hostMimeVersionFile) but Nix would install ${nixVersion}."
            errorEcho "Mixing < 2.5 and >= 2.5 MIME databases creates C/C++/ObjC parent cycles that crash Qt 5 apps (KDE Plasma 5)."
            errorEcho "Set 'custom.shared-mime-info.useStable = true;' in this host's hosts/*.nix file."
            exit 1
          fi
        fi
      '';
    })
  ];
}

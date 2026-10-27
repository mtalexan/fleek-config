{ lib, ... }: {
  options.custom.shared-mime-info = with lib; {
    useStable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use shared-mime-info from the stable nixpkgs input (pkgs.shared-mime-info-stable, currently 2.4) for the
        home-manager MIME database instead of the nixpkgs default.

        Host systems that have shared-mime-info <2.5 will encounter circular dependencies in the MIME database if they
        don't enable this, because Freedesktop's shared-mime-info 2.5 release reversed the C/C++/Objective-C/Objective-C++
        sub-class-of relationships. This most notably causes problems with Qt, since it didn't or handle this possible
        issue until Qt 6.5, so KDE Plasma 5 in Kubuntu 24.04 will crash the entire DE on start.

        Without this enabled, the host shared-mime-info version is checked on activation to make sure it's >= 2.5.
        With this enabled, we use a pinned shared-mime-info 2.4.
      '';
    };
  };
}

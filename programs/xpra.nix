{ config, lib, pkgs, ... }:
let
  cfg = config.custom.xpra;
  xpra = lib.getExe' pkgs.xpra "xpra";
in {
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.xpra ];

    systemd.user.services.xpra = {
      Unit.Description = "Xpra persistent application server";

      Service = {
        Type = "simple";
        Environment = [ "XAUTHORITY=%h/.Xauthority" ];
        ExecStart = "${xpra} seamless :${toString cfg.display} --daemon=no --backend=x11 --sharing=yes --exit-with-children=no";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}

# vim: ts=2:sw=2:expandtab

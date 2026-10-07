{ lib, ... }: {
  options.custom.xpra = {
    enable = lib.mkEnableOption "the Xpra persistent application server";

    display = lib.mkOption {
      type = lib.types.ints.between 0 65535;
      default = 100;
      description = "X11 display number used by the Xpra server.";
    };
  };
}

# vim: ts=2:sw=2:expandtab

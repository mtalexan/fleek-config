{ lib, ... }: {
  options.custom.certs = with lib; {
    bundle = mkOption {
      type = types.nullOr types.str;
      default = "/etc/ssl/certs/ca-certificates.crt";
      description = "The per-system path to the Root CA certificates bundle. If set null, none of the variables for this are overidden.";
    };
  };
}
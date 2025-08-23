{ pkgs, misc, lib, config, ... }: {

  options.custom.certs = with lib; {
    bundle = mkOption {
      type = types.nullOr types.str;
      default = "/etc/ssl/certs/ca-certificates.crt";
      description = "The per-system path to the Root CA certificates bundle. If set null, none of the variables for this are overidden.";
    };
  };

  config.home.sessionVariables = lib.mkIf (config.custom.certs.bundle != null) {
      # use the system certs for Node clients like VSCode
      NODE_EXTRA_CA_CERTS = config.custom.certs.bundle;
      # All Nix commands should use the system certs
      NIX_SSL_CERT_FILE = config.custom.certs.bundle;
      # use the system certs for Python code using the Requests module
      REQUESTS_CA_BUNDLE = config.custom.certs.bundle;
      # use the system certs for other Python code
      SSL_CERT_FILE = config.custom.certs.bundle;
      # curl uses yet another variable
      CURL_CA_BUNDLE = config.custom.certs.bundle;
  };
}

# vim: ts=2:sw=2:expandtab

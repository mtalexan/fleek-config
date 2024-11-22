{ pkgs, misc, lib, config, ... }: {
  config = {
    home.sessionVariables = {
      # use the system certs for Node clients like VSCode
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      # All Nix commands should use the system certs
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      # use the system certs for Python code using the Requests module
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
      # use the system certs for other Python code
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}

# vim: sw=2:expandtab

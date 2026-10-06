{ pkgs, lib, config, ... }:
# Two independent switches:
#   custom.ssh-agent.enable    start ssh-agent at login and set SSH_AUTH_SOCK in bashrc and zshrc
#   custom.ssh-agent.auto-load-keys   load ~/.ssh private keys into the running agent
# With only auto-load-keys, the host agent and its SSH_AUTH_SOCK are left in place.
let
  cfg = config.custom.ssh-agent;
  socket = config.services.ssh-agent.socket;
  openssh = config.services.ssh-agent.package;
  ssh-add = lib.getExe' openssh "ssh-add";
  ssh-keygen = lib.getExe' openssh "ssh-keygen";

  shellSocketExport = ''
    # ssh-agent is the default socket name from home-manager services.ssh-agent.
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/${socket}"
  '';

  # Discover private keys when the unit runs. The set of files in ~/.ssh is not
  # known when this config is built.
  addKeys = pkgs.writeShellScript "ssh-agent-add-keys" ''
    set -eu
    sock="$SSH_AUTH_SOCK"
    i=0
    while [ "$i" -lt 50 ]; do
      if [ -S "$sock" ]; then
        break
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
      i=$((i + 1))
    done
    if [ ! -S "$sock" ]; then
      echo "ssh-agent socket not available: $sock" >&2
      exit 1
    fi

    shopt -s nullglob
    for f in "''${HOME}/.ssh"/*; do
      [ -f "$f" ] || continue
      base="''${f##*/}"
      case "$base" in
        *.pub|config|known_hosts*|authorized_keys*|environment|rc)
          continue
          ;;
      esac
      if ${ssh-keygen} -y -f "$f" >/dev/null 2>&1; then
        ${ssh-add} "$f" || echo "failed to add $f" >&2
      fi
    done
  '';
in
{
  options.custom.ssh-agent = {
    enable = lib.mkEnableOption ''
      the home-manager ssh-agent user service. Also sets SSH_AUTH_SOCK in
      bashrc and zshrc to that service's socket.
      Leave this off when the host already provides an agent.
    '';

    auto-load-keys = lib.mkEnableOption ''
      loading private keys from ~/.ssh into the running agent at login.
      Uses this module's socket when custom.ssh-agent.enable is set, and the
      host SSH_AUTH_SOCK otherwise.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.ssh-agent.enable = true;

      # Home-manager writes SSH_AUTH_SOCK for login shells only.
      # Kitty starts non-login shells, which skip that file.
      programs.bash.initExtra = shellSocketExport;
      programs.zsh.initContent = shellSocketExport;
    })

    (lib.mkIf cfg.auto-load-keys {
      systemd.user.services.ssh-agent-add-keys = {
        Unit = {
          Description = "Load ~/.ssh private keys into ssh-agent";
          After = lib.optionals cfg.enable [ "ssh-agent.service" ];
          PartOf = lib.optionals cfg.enable [ "ssh-agent.service" ];
        };

        Service = {
          Type = "oneshot";
          # Stays active so PartOf restarts this unit with ssh-agent.service.
          RemainAfterExit = cfg.enable;
          # never: an unexpected passphrase must fail this file, not hang login on a dialog
          Environment =
            [ "SSH_ASKPASS_REQUIRE=never" ]
            ++ lib.optional cfg.enable "SSH_AUTH_SOCK=%t/${socket}";
          ExecStart = addKeys;
        };

        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}

# vim: ts=2:sw=2:expandtab

{ pkgs, lib, config, ... }:
# Adds a systemd user service that starts the ssh-agent at login.
# Adds the SSH_AUTH_SOCK to the shell rc files.
# Adds a systemd user service that starts after the agent and automatically loads
#  all key files from ~/.ssh/ into the agent so they can be used.
# WARNING: Some desktop environments already ship an ssh-agent that's enabled by default.
#          This will override that agent's socket setting.
let
  socket = config.services.ssh-agent.socket;
  openssh = config.services.ssh-agent.package;
  ssh-add = lib.getExe' openssh "ssh-add";
  ssh-keygen = lib.getExe' openssh "ssh-keygen";

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
  # Starts ssh-agent at login and exports SSH_AUTH_SOCK for login shells, zsh,
  # and the systemd/D-Bus session. The bash snippet below covers non-login bash.
  services.ssh-agent.enable = true;

  # ssh-agent -a refuses to start when the socket path already exists.
  systemd.user.services.ssh-agent.Service.ExecStartPre = "${pkgs.coreutils}/bin/rm -f %t/${socket}";

  systemd.user.services.ssh-agent-add-keys = {
    Unit = {
      Description = "Load ~/.ssh private keys into ssh-agent";
      After = [ "ssh-agent.service" ];
      Requires = [ "ssh-agent.service" ];
    };

    Service = {
      Type = "oneshot";
      # never: an unexpected passphrase must fail this file, not hang login on a dialog
      Environment = [
        "SSH_AUTH_SOCK=%t/${socket}"
        "SSH_ASKPASS_REQUIRE=never"
      ];
      ExecStart = addKeys;
    };

    Install.WantedBy = [ "default.target" ];
  };

  # Home-manager writes the socket export into ~/.profile only. Kitty starts
  # non-login shells, which do not source that file.
  # Keep an existing SSH_AUTH_SOCK when SSH_CONNECTION is set so ssh -A is preserved.
  programs.bash.initExtra = ''
    if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/${socket}"
    fi
  '';
}

# vim: ts=2:sw=2:expandtab

{ lib, config, ... }: {
  # On non-NixOS systems, Nix relies on the host's nscd (Name Service Cache Daemon)
  # socket to correctly resolve users/groups/hosts across the different libc versions
  # in play (the Nix packages' glibc vs. the host's glibc). If nscd isn't running,
  # NSS lookups can silently misbehave (e.g. DNS resolution or user lookups failing).
  #
  # This adds a home-manager activation step that checks for the nscd socket and prints
  # a warning if it's missing, so the problem is visible during `home-manager switch`.

  home.activation.checkNscdSocket = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nscdSocketFound=""
    for sock in /var/run/nscd/socket /run/nscd/socket; do
      if [ -S "$sock" ]; then
        nscdSocketFound="$sock"
        break
      fi
    done

    if [ -z "$nscdSocketFound" ]; then
      warnEcho "No nscd socket found (checked /var/run/nscd/socket and /run/nscd/socket)."
      warnEcho "On non-NixOS systems nscd is recommended so Nix can correctly resolve"
      warnEcho "users, groups, and hosts across mismatched glibc versions."
      warnEcho "Consider enabling it, e.g.: sudo systemctl enable --now nscd.service"
    fi
  '';
}

# vim: ts=2:sw=2:expandtab

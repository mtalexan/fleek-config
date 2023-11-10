#!/bin/bash

# Sets up nix passthru from the host system for a toolbox/distrobox
#
# Once setup, all the nix tools and home-manager will work from the host,
# any any prompt or anything will function transparently.
# Nix uses cacertificates configured by the daemon, so the nix tools inside
# the toolbox/distrobox will not use the cacerts from within the container
# for the purposes of nix operations.

echo "Setup nix"

die() 
{
    [ $# -eq 0 ] || echo >&2 "ERROR: " "$@"
    exit 1
}

warn()
{
    [ $# -eq 0 ] || echo >&2 "WARN:" "$@"
}

# all host files are under this root
readonly hostfs="/run/host"

[ -e $hostfs ] || die "Not in a toolbox/distrobox!"
if [ ! -e $hostfs/nix ] ; then
    echo >&2 "Nix not present in host system, skipping"
else
    if [ -e /nix ]; then
        echo >&2 "Nix already setup in toolbox/distrobox"
    else

        # create a temp file with the fixed block we need to include in some files

        tmp_text=$(mktemp) || die "Creating temp file 1"

        cat > ${tmp_text} <<EOF

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix

EOF

        [ $? -eq 0 ] || die "Creating file to source nix"

        for P in /nix /var/nix-profile /etc/nix /etc/profile.d/nix.sh /etc/sudoers.d/nix-sudo-env; do
            # silent skip it if it doesn't exist on the host
            [ -e ${hostfs}$P ] || continue
            set -x
            sudo ln -s $hostfs$P $P || die "$P symlink"
            set +x
        done

        tmp_rc=$(mktemp) || die "Creating tempfile 2"

        # add the block of text to the top of each of these files, creating them if necessary.
        for F in /etc/bashrc.bashrc /etc/bashrc /etc/zshrc ; do
            # always create these files if they don't exist!

            echo "Adding sourcing of nix-daemon.sh to $F"
            cat $tmp_text > $tmp_rc || die "Initially populating replacement for $F"

            if [ -e $F ]; then
                cat $F >> $tmp_rc || die "Adding existing content from $F to replacement"
            fi
            sudo mv $tmp_rc $F || die "Replacing $F"
        done

        # succeeded, but needs to be done before the profile is loaded.
        warn "You must exit and re-enter for changes to take effect!"
    fi
fi
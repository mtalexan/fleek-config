#!/bin/bash

# Makes sure that if /var/run/docker.sock is present (even as symlink), the group 
# that actually owns it is a recognized group in the container, mapped to "docker" 
# if not already mapped, and the main user is part of that group.

echo "Mapping Docker socket"

die() 
{
    [ $# -eq 0 ] || echo >&2 "ERROR: " "$@"
    exit 1
}

warn()
{
    [ $# -eq 0 ] || echo >&2 "WARN:" "$@"
}

# Checks if the specified group name exists already
# Args:
#  1: group name to look for
# Returns:
#  0 the group exists
#  1 the group doesn't exist
#  2 error, couldn't look for group
check_for_group()
{
    if ! command -v getent &>/dev/null ; then
        echo "ERROR: can't check for groups"
        return 2
    fi
    if ! getent group $1 ; then
        return 1
    else
        return 0
    fi
}

# Adds a group to the system.  Assumes it doesn't already exist
# Args:
#  1: group name
#  2: gid
# Return:
#  0 successfully added
#  1 didn't add successfully
#  2 missing tools to be able to add
add_group()
{
    local the_group=$1
    local the_gid=$2

    if ! command -v sudo &>/dev/null ; then
        warn "Can't modify groups, 'sudo' not available"
        return 2
    elif command -v addgroup &>/dev/null ; then
        sudo addgroup --gid ${the_gid} ${the_group}
        if [ $? -ne 0 ] ; then
            return 1
        fi
    elif command -v groupadd &>/dev/null ; then
        sudo groupadd --gid ${the_gid} ${the_group}
        if [ $? -ne 0 ] ; then
            return 1
        fi
    else
        warn "Missing command 'addgroup' or 'groupadd'"
        return 2
    fi

    return 0
}

# only worry about it if the docker socket is mapped into the container,
# and the docker group doesn't already exist
if [ -e /var/run/docker.sock ] && ! check_for_group docker ; then
    # only if we can get file info can we do anything
    if ! command -v stat &>/dev/null || ! command -v readlink &>/dev/null ; then
        warn "Can't check docker.sock access, requires 'stat', 'readlink'"
    else
        socket_group=$(stat -c '%G' -t $(readlink /var/run/docker.sock))
        docker_gid=$(stat -c '%g' -t $(readlink /var/run/docker.sock))
        # is there already a known group permission on the socket?
        if [  "${socket_group}" != "UNKNOWN" ] ; then
            warn "docker socket already has known group ${socket_group}"
        elif [ -z "${docker_gid}" ] ; then
            warn "couldn't get GID of 'docker' group from docker.sock"
        else
            # socket group isn't known by the system, map the GID to  'docker'
            add_group docker ${docker_gid} || true
        fi
    fi
fi

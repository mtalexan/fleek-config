#!/bin/bash
# Adds Root CAs from a volume mounted directory to the target container.
# Attempts to determine which location to use, and deals with some distros
# not supporting recursive search on the folder.

echo "Adding Root CAs"

# must not end in /
readonly hostfs="/run/host"

# fixed folder for even more certs
readonly extra_ca_certs="${hostfs}${DISTROBOX_CONFIG_DIR}/certs"

die() 
{
    [ $# -eq 0 ] || echo >&2 "ERROR: " "$@"
    exit 1
}

warn()
{
    [ $# -eq 0 ] || echo >&2 "WARN:" "$@"
}

# Sets HOST_ROOT_CA_MOUNT
get_host_extra_root_cas()
{
    if [ -e "${hostfs}/usr/share/pki/ca-trust-source/anchors" ] ; then
        # Fedora, RedHat, OpenSuse, Arch, Manjaro, etc
        echo "Detected Fedora-like host"
        HOST_ROOT_CA_MOUNT="${hostfs}/usr/share/pki/ca-trust-source/anchors"
    elif [ -e "${hostfs}/usr/local/share/ca-certificates" ] ; then
        # Ubuntu, Debian, Pop_OS!
        echo "Detected Debian-like host"
        HOST_ROOT_CA_MOUNT="${hostfs}/usr/local/share/ca-certificates"
    else
        die "Unrecognized host type"
    fi
}

# A pre-init-hook for distrobox when creating an image that will add CAs from
# a host directory to the image.
# Note that some cloud images don't have even the most basic necessary tools
# during pre-init.  Usually these images also hardcode disabling of all CA certificate
# checks, but not all do.  We provide this same hook as both a pre-init-hooks
# for distros that need it in order to install anything, and as a regular init-hook
# for distros to have after they're ready to be used if they couldn't get the
# certificates during pre-init.
# Run as:
#    distrobox create --pre-init-hooks /abs/path/to/this --init-hooks /abs/path/to/this ...other args...

# Checks if a CA update command is provided, and runs it.
# Args:
#  1: the CA update command to run
update_system_ca()
{
    local os_ca_update_cmd="$1"
    # Some systems will run this tool later and support unauthenticated initial updates
    if [ -n "${os_ca_update_cmd}" ] ; then
        echo "Updating system"
        # some files were updated or added, re-run the ca update
        # This may not produce output
        sudo bash -c "${os_ca_update_cmd}"
        if [ $? -ne 0 ] ; then
            echo "Unable to update CA trust"
            return 1
        else
            echo "CA update complete"
        fi
    fi
}

# Adds root CAs from a host folder to the system CA list.
# Reproduces any tree of folders from the host into the target CA folder, which may
# not be allowed for all distros.
# Run always, only updates if changes exist.
# Args:,
#  1: absolute path of host location to find CAs
#  2: absolute path in container where CAs need to go for trust update
#  3: (optional) command in container to update trust
ca_update_recursive() {
    if ! command -v wc &>/dev/null || ! command -v sudo &>/dev/null ; then
        echo "ERROR: CA installation requires 'wc' and 'sudo'"
        return 0 # don't halt the container startup
    fi

    # must be an absolute path to a host volume mount
    local container_host_ca_dir="$1"
    # location the distro requires the CAs to be added to
    local os_ca_dir="$2"
    local os_ca_update_cmd="$3"

    echo "Checking CAs..."

    # make sure the directory exists
    sudo mkdir -p "${os_ca_dir}"

    # Copy the automatically listed files and directories from the 
    # host folder into the target folder recursively if they're newer, 
    # printing in verbose so we can count how many files were actually copied
    files_copied=$(sudo cp -uvr -t "${os_ca_dir}" ${container_host_ca_dir}/* | wc -l)
    if [ ${files_copied} -eq 0 ]; then
        echo "No updates needed"
    else
        echo "${files_copied} CAs modified." 

        update_system_ca "${os_ca_update_cmd}" || return $?
    fi
}

# Adds root CAs from a host folder to the system CA list.
# Only copies files from the top-level of Arg1 into the container
# Run always, only updates if changes exist.
# Args:,
#  1: absolute path of host location to find CAs
#  2: absolute path in container where CAs need to go for trust update
#  3: (optional) command in container to update trust
ca_update_flat() {
    if ! command -v wc &>/dev/null || ! command -v sudo &>/dev/null; then
        echo "ERROR: CA installation requries 'wc' and 'sudo'"
        return 0 # don't halt the container startup
    fi

    # must be an absolute path to a host volume mount
    local container_host_ca_dir="$1"
    # location the distro requires the CAs to be added to
    local os_ca_dir="$2"
    local os_ca_update_cmd="$3"

    echo "Checking CAs..."

    # make sure the directory exists
    sudo mkdir -p "${os_ca_dir}"

    # Copy the automatically listed files from only the top level of the
    # host folder into the single-level target folder if they're newer, 
    # printing in verbose so we can count how many files were actually copied.
    # Will print to stderr that it was unable to copy any sub-folders, which is
    # desirable to leave in the container logs
    files_copied=$(sudo cp -uv -t "${os_ca_dir}" ${container_host_ca_dir}/* | wc -l)
    if [ ${files_copied} -eq 0 ]; then
        echo "No updates needed"
    else
        echo "${files_copied} CAs modified." 

        update_system_ca "${os_ca_update_cmd}" || return $?
    fi
}

# Adds root CAs from a host folder to the system CA list.
# Some distros don't allow subfolders of the distro CA folder, so flatten all
# files from all subdirectories in the host folder to install into the distro 
# CA folder.
# Run always, only updates if changes exist.
# WARNING: if subfolders of the host folder have files of the same name as other folders, 
#          this will always detect that files have been updated and will always re-copy
#          and re-run the CA update.
# Args:
#  1: absolute path of host location to find CAs
#  2: absolute path in container where CAs need to go for trust updates
#  3: command in container to update trust
ca_update_flatten() {
    if ! command -v find &>/dev/null || ! command -v readarray &>/dev/null || ! command -v wc &>/dev/null || ! command -v sudo &>/dev/null ; then
        echo >&2 "ERROR: CA installation with flattening requries 'find', 'readarray', 'wc', and 'sudo'"
        return 0 # don't halt the container startup
    fi

    # must be an absolute path to a host volume mount
    local container_host_ca_dir="$1"
    # location the distro requires the CAs to be added to
    local os_ca_dir="$2"
    local os_ca_update_cmd="$3"

    local files=()

    # get the file list since some may contain spaces
    readarray -t files < <(sudo find ${container_host_ca_dir} -type f)
    if [ ${#files[@]} -eq 0 ] ; then
        echo "No CAs found to add"
        return 0
    fi

    echo "Checking CAs..."

    # make sure the directory exists
    sudo mkdir -p "${os_ca_dir}"

    # Copy the list of quoted files into the single level target folder
    # if they're newer, printing in verbose so we can count how many
    # files were actually copied
    files_copied=$(sudo cp -uv -t "${os_ca_dir}" "${files[@]}" | wc -l)
    if [ ${files_copied} -eq 0 ]; then
        echo "No updates needed"
    else
        echo "${files_copied} CAs modified." 

        update_system_ca "${os_ca_update_cmd}" || return $?
    fi
}

if ! command -v sudo &>/dev/null ; then
    # a set of distro cloud images don't even have sudo, let alone any tools capable of
    # checking CA certificates, so don't bother doing anything with them on the first boot
    echo "Cloud image incapable of any authentication, skipping CA checks"
else
    # sets HOST_ROOT_CA_MOUNT
    get_host_extra_root_cas

    if [ -e "/usr/share/pki/ca-trust-source/anchors" ] ; then
        # Fedora, RedHat, Arch(?), Manjaro(?)
        echo "Detected Fedora-like"

        for  D in "${HOST_ROOT_CA_MOUNT}" "${extra_ca_certs}"; do
            [ -d "$D" ] || continue
            # the update command may not exist yet for some cloud-images, so only supply it if it does
            ca_update_flatten "${D}" "/usr/share/pki/ca-trust-source/anchors" "$(command -v update-ca-trust)"
        done
    elif [ -e "/usr/local/share/ca-certificates" ] ; then
        # Ubuntu, Debian, Pop_OS!
        echo "Detected Debian-like"
        for  D in "${HOST_ROOT_CA_MOUNT}" "${extra_ca_certs}"; do
            [ -d "$D" ] || continue
            # the update command may not exist yet for some cloud-images, so only supply it if it does
            ca_update_recursive "${D}" "/usr/local/share/ca-certificates" "$(command -v update-ca-certificates)"
        done
    else
        die "Unrecognized distribution"
    fi
fi

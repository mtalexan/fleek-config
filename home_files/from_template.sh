#!/bin/bash

# Creates a home_files directory in one of the per-host config folders from one of the template folders in this folder
# if it doesn't exist, by copying everything over.  If the destination folder exists already, it will instead check if
# the files in the destination need to be updated from the source. This allows files/folder to be removed from the
# destination location if they aren't needed, but allows the ones that are kept to be updated.
# Args:
#  1: Name of the template folder (with or without the 'template_' prefix) that's in this folder
#  2: Hostname folder to put the copy of the template in (must be a folder up 1 directory from this script)

set -o pipefail

CMD="$(basename "$0")"
readonly CMD

SCRIPT_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")"
readonly SCRIPT_DIR

HOST_ROOT_PATH="$(readlink -e "${SCRIPT_DIR}/..")"
readonly HOST_ROOT_PATH

die() {
    [ $# -eq 0 ] || echo >&2 "ERROR: " "$@"
    exit 1
}
export -f die

warn() {
    echo >&2 "WARNING: " "$@"
}
export -f warn

[ $# -eq 2 ] || die "USAGE: ${CMD} <template_folder> <hostname>"

template_folder=$1
hostname_folder=$2

# check the one with 'template_' prefix added so we don't accidentally allow
if ! [[ ${template_folder} =~ template_* ]] && [ -d "${SCRIPT_DIR}/template_${template_folder}" ]; then
    template_folder="template_${template_folder}"
    echo "From template folder: ${template_folder}"
elif [[ ${template_folder} =~ template_* ]] && [ -d "${SCRIPT_DIR}/${template_folder}" ]; then
    echo "From template folder: ${template_folder}"
else
    die "No such template folder (w/ or w/o 'template_' prefix): ${template_folder}"
fi
readonly template_folder

[ -d "${HOST_ROOT_PATH}/${hostname_folder}" ] || die "No such host folder: ${HOST_ROOT_PATH}/${hostname_folder}"
readonly hostname_folder

dest_path="${HOST_ROOT_PATH}/${hostname_folder}/home_files"
# make the 'home_files' folder in the hostname folder if it doesn't exist
mkdir -p "${dest_path}" || die "Making ${hostname_folder}/home_files"

source_path="${SCRIPT_DIR}/${template_folder}"
# add the output folder name, but without the 'template_' prefix
dest_path="${dest_path}/${template_folder#template_}"
readonly source_path
readonly dest_path

if [ ! -d "${dest_path}" ]; then
    echo "Creating copy of ${template_folder} in ${hostname_folder}"

    # copy everything from source to dest
    cp -a "${source_path}" "${dest_path}" || die "Copying files"

    echo "SUCCESS"
    echo "Find the new template in: $dest_path"
else
    # find all the regular files in the destination to see if they need to be updated
    dest_files=()
    readarray -t dest_files < <(find "${dest_path}" -mindepth 1 -type f)

    echo "Updating any older files for the ${template_folder} in ${hostname_folder}"

    for F in "${dest_files[@]}"; do
        # replace the dest_path with the source_path in the file
        SF="${source_path}/${F#${dest_path}}"
        # make it a relative symlink so the git repo is still self-contained
        cp -uai "$SF" "$F" || die "Updating file ($F) with file ($SF)"
    done

    echo "SUCCESS"
fi
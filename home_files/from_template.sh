#!/bin/bash

# Creates a home_files directory in one of the per-host config folders from one of the template folders in this folder.
# Recursively copies to the appropriate non-template name and then swaps all files for relative symlinks pointing back
# to the template version.  The caller is then responsible for removing symlinks they don't want in that specific copy,
# and setting the relevant 'home.file.<name>.enable = true' in the host-specific nix file.
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

if [ -d "${SCRIPT_DIR}/${template_folder}" ]; then
    echo "From template folder: ${template_folder}"
elif [ -d "${SCRIPT_DIR}/template_${template_folder}" ]; then
    template_folder="template_${template_folder}"
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

# copy everything from source to dest
cp -a "${source_path}" "${dest_path}" || die "Copying files"

# find all the regular files in the destination
dest_files=()
readarray -t dest_files < <(find "${dest_path}" -mindepth 1 -type f)

for F in "${dest_files[@]}"; do
    # replace the dest_path with the source_path in the file
    SF="${source_path}/${F#${dest_path}}"
    # remove the file we're going to replace
    rm "$F" || die "Removing file to replace: $F"
    # make it a relative symlink so the git repo is still self-contained
    ln -sr "$SF" "$F" || die "Replacing file ($F) with symlink ($SF)"
done

echo "SUCCESS"
echo "Find the new template in: $dest_path"
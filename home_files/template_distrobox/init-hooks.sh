#!/bin/bash

echo "Running init hooks"

if ! command -v dirname &>/dev/null; then
    echo "ERROR: Cannot determine script location, add 'dirname' to resolve"
    exit 1
fi

if command -v readlink &>/dev/null ; then
    SCRIPT_DIR="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")"
else
    # can't resolve symlinks
    echo "WARN: cannot resolve symlinks, add 'readlink' to resolve"
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
fi
readonly SCRIPT_DIR
export DISTROBOX_CONFIG_DIR=${SCRIPT_DIR}

if ! command -v find &>/dev/null; then
    echo >&2 "WARN: No 'find' command, can't run pre-init-hooks"
else
    for F in $(find ${SCRIPT_DIR}/init-hooks.d/ -maxdepth 1 -mindepth 1 | sort -u); do
        echo "$F"
        source "$F"
    done
fi
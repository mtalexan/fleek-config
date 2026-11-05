#!/usr/bin/env bash
# herdr-bridge is on PATH via the plugin's runtimeInputs. The first argument selects the editor variant.
exec herdr-bridge request-edit --variant "${1:-default}"

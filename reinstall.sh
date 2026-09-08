#!/usr/bin/env bash
#
# MasterR re-installer.
# Re-runs the MasterR installation workflow with the --reinstall flag.
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

if [ -f "$SCRIPT_DIR/install.sh" ]; then
    exec "$SCRIPT_DIR/install.sh" --reinstall "$@"
fi

# Fallback if run standalone or outside the repository clone
DIR="${XDG_DATA_HOME:-$HOME/.local/share}/masterr"
if [ -f "$DIR/install.sh" ]; then
    exec "$DIR/install.sh" --reinstall "$@"
fi

echo ":: Fetching latest MasterR bootstrap..."
curl -fsSL https://raw.githubusercontent.com/Krish-Kamani/MasterR/main/install.sh | bash -s -- --reinstall "$@"

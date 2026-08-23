#!/usr/bin/env bash
# package-install-launch.sh: Launches the interactive package installer in a floating window

pkg="$1"
source="${2:-OAR}"
version="${3:-}"

if [ -z "$pkg" ]; then
    exit 0
fi

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
INSTALL_PY="$SCRIPT_DIR/package-install.py"

if command -v ghostty >/dev/null 2>&1; then
    ghostty --class="pkg-installer" --title="Installing $pkg" -e python3 "$INSTALL_PY" "$pkg" "$source" "$version" &
elif command -v kitty >/dev/null 2>&1; then
    kitty --class="pkg-installer" --title="Installing $pkg" python3 "$INSTALL_PY" "$pkg" "$source" "$version" &
else
    xterm -class "pkg-installer" -T "Installing $pkg" -e python3 "$INSTALL_PY" "$pkg" "$source" "$version" &
fi

#!/usr/bin/env bash
# open-file-target.sh: opens a folder in the default file manager,
# or if a file is provided, opens the folder where the file is located.

target="$1"
kind="$2"

if [ -z "$target" ]; then
    exit 0
fi

if [ "$kind" = "dir" ] || [ -d "$target" ]; then
    # Open the folder directly in the default file manager
    if command -v dolphin >/dev/null 2>&1; then
        dolphin "$target" >/dev/null 2>&1 &
    else
        xdg-open "$target" >/dev/null 2>&1 &
    fi
else
    # It's a file: open the folder where the file is located
    parent="$(dirname "$target")"
    if command -v dolphin >/dev/null 2>&1; then
        dolphin --select "$target" >/dev/null 2>&1 &
    elif command -v gdbus >/dev/null 2>&1; then
        gdbus call --session --dest org.freedesktop.FileManager1 \
            --object-path /org/freedesktop/FileManager1 \
            --method org.freedesktop.FileManager1.ShowItems \
            "['file://$target']" "" >/dev/null 2>&1 || xdg-open "$parent" >/dev/null 2>&1 &
    else
        xdg-open "$parent" >/dev/null 2>&1 &
    fi
fi

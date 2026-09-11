#!/usr/bin/env bash
# hybrid-launch.sh — launches an application with GPU offload (prime-run) if available, or natively.
set -euo pipefail

APP="${1:-}"
shift || true

if [ -z "$APP" ]; then
    exit 0
fi

# Detect prime-run availability
RUNNER=""
if command -v prime-run >/dev/null 2>&1; then
    RUNNER="prime-run"
fi

case "$APP" in
    browser|zen-browser)
        for b in zen-browser zen-browser-bin brave-browser brave google-chrome-stable chromium firefox; do
            if command -v "$b" >/dev/null 2>&1; then
                if [ -n "$RUNNER" ]; then
                    exec "$RUNNER" "$b" "$@"
                else
                    exec "$b" "$@"
                fi
            fi
        done
        command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Browser Not Found" "Please install Zen Browser or another supported browser."
        exit 1
        ;;
    editor|vscodium)
        for e in vscodium codex code; do
            if command -v "$e" >/dev/null 2>&1; then
                if [ -n "$RUNNER" ]; then
                    exec "$RUNNER" "$e" "$@"
                else
                    exec "$e" "$@"
                fi
            fi
        done
        command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Editor Not Found" "Please install VSCodium or VS Code."
        exit 1
        ;;
    *)
        if command -v "$APP" >/dev/null 2>&1; then
            if [ -n "$RUNNER" ]; then
                exec "$RUNNER" "$APP" "$@"
            else
                exec "$APP" "$@"
            fi
        else
            command -v notify-send >/dev/null 2>&1 && notify-send -u normal "Application Not Found" "Command '$APP' is not installed."
            exit 1
        fi
        ;;
esac

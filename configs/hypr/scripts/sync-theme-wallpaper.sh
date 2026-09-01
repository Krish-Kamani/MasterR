#!/usr/bin/env bash
set -euo pipefail

# Cache destinations
SDDM_CACHE_DIR="/var/cache/masterr"
SDDM_BG="$SDDM_CACHE_DIR/current_wallpaper.png"
GRUB_BG="/boot/grub/themes/masterr-glass/background.png"
LOCAL_SDDM_BG="$HOME/.local/share/sddm-themes/masterr-glass/assets/background.png"
LOCAL_GRUB_BG="$HOME/.local/share/grub-themes/masterr-glass/background.png"

# Target input
WP="${1:-}"
if [ -z "$WP" ]; then
    STATE="${XDG_STATE_HOME:-$HOME/.local/state}/masterr-wallpaper"
    STILL="${XDG_STATE_HOME:-$HOME/.local/state}/masterr-wallpaper-still.png"
    if [ -f "$STILL" ]; then
        WP="$STILL"
    elif [ -f "$STATE" ]; then
        WP=$(cat "$STATE")
    fi
fi

[ -n "$WP" ] && [ -f "$WP" ] || exit 0

TMP_PNG=$(mktemp /tmp/masterr-theme-bg-XXXXXX.png)
trap 'rm -f "$TMP_PNG"' EXIT

is_video() {
    case "${1##*.}" in
        [Mm][Pp]4|[Ww][Ee][Bb][Mm]|[Mm][Kk][Vv]|[Mm][Oo][Vv]|[Gg][Ii][Ff]) return 0 ;;
        *) return 1 ;;
    esac
}

# Render 1920x1080 crisp PNG frame
if is_video "$WP"; then
    ffmpeg -y -loglevel error -ss 00:00:01 -i "$WP" -frames:v 1 -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" "$TMP_PNG" 2>/dev/null || \
    ffmpeg -y -loglevel error -i "$WP" -frames:v 1 -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" "$TMP_PNG" 2>/dev/null
else
    ffmpeg -y -loglevel error -i "$WP" -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" "$TMP_PNG" 2>/dev/null || \
    convert "$WP" -resize 1920x1080^ -gravity center -extent 1920x1080 "$TMP_PNG" 2>/dev/null || \
    cp "$WP" "$TMP_PNG"
fi

[ -s "$TMP_PNG" ] || exit 0

# 1. Update SDDM Cache
if [ -d "$SDDM_CACHE_DIR" ] && [ -w "$SDDM_CACHE_DIR" ]; then
    cp "$TMP_PNG" "$SDDM_BG.tmp" 2>/dev/null && mv "$SDDM_BG.tmp" "$SDDM_BG" 2>/dev/null || true
fi

# 2. Update GRUB Theme Background
if [ -w "$GRUB_BG" ]; then
    cp "$TMP_PNG" "$GRUB_BG.tmp" 2>/dev/null && mv "$GRUB_BG.tmp" "$GRUB_BG" 2>/dev/null || true
elif command -v sudo >/dev/null 2>&1 && [ -x /usr/local/bin/sync-grub-bg ]; then
    sudo -n /usr/local/bin/sync-grub-bg "$TMP_PNG" 2>/dev/null || true
fi

# 3. Update User Local Staging Theme Backgrounds
mkdir -p "$(dirname "$LOCAL_SDDM_BG")" "$(dirname "$LOCAL_GRUB_BG")"
cp "$TMP_PNG" "$LOCAL_SDDM_BG" 2>/dev/null || true
cp "$TMP_PNG" "$LOCAL_GRUB_BG" 2>/dev/null || true

exit 0

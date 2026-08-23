#!/bin/sh
MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"
export MAGICK_CONFIGURE_PATH

flags="${XDG_STATE_HOME:-$HOME/.local/state}/masterr/flags.json"
wpdir=$(jq -r '.wallpaperDir // ""' "$flags" 2>/dev/null || echo "")
[ -n "$wpdir" ] || wpdir=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/masterr-wallpaper-dir" 2>/dev/null || true)
[ -n "$wpdir" ] || wpdir="$HOME/MasterR/wallpapers"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/masterr-wp-thumbs"
mkdir -p "$cache"

for f in "$cache"/*.png; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .png)"
    [ -n "$(find "$wpdir" -type f -name "$base" -print -quit)" ] || rm -f "$f"
done

find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | while IFS= read -r src; do
    thumb="$cache/$(basename "$src").png"
    if [ ! -s "$thumb" ] || [ "$src" -nt "$thumb" ]; then
        case "$src" in
            *.[Mm][Pp]4|*.[Ww][Ee][Bb][Mm]|*.[Mm][Kk][Vv]|*.[Mm][Oo][Vv])
                ffmpeg -y -loglevel quiet -i "$src" -frames:v 1 -vf 'scale=512:-2' -f image2 -c:v png "$thumb.tmp" 2>/dev/null
                ;;
            *)
                magick "${src}[0]" -strip -resize 512x "png:$thumb.tmp" 2>/dev/null
                ;;
        esac
        if [ -s "$thumb.tmp" ]; then
            mv "$thumb.tmp" "$thumb"
        else
            rm -f "$thumb.tmp"
        fi
    fi
done

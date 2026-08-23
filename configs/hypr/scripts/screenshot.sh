#!/usr/bin/env bash

# Screenshot utility for Hyprland with automatic clipboard copy, notification, and Satty annotation editor
set -e

DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE="${DIR}/Screenshot_${TIMESTAMP}.png"
TEMP_FILE="/tmp/screenshot_current.png"

MODE="${1:-area}"

case "$MODE" in
    area|region|select)
        # Select area with slurp and capture with grim
        GEOM=$(slurp -d -b "#00000088" -c "#ffffff" -w 2 2>/dev/null)
        if [ -z "$GEOM" ]; then
            # Selection cancelled by user (e.g. Escape or right click)
            exit 0
        fi
        grim -g "$GEOM" "$FILE"
        ;;
    full|fullscreen|screen|output)
        # Capture full screen
        grim "$FILE"
        ;;
    window)
        # Capture selected/active window using hyprctl and slurp
        GEOM=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' 2>/dev/null | slurp -d -b "#00000088" -c "#ffffff" -w 2 2>/dev/null)
        if [ -z "$GEOM" ]; then
            exit 0
        fi
        grim -g "$GEOM" "$FILE"
        ;;
    satty|edit)
        # Directly launch satty on latest screenshot or area
        if [ -f "$TEMP_FILE" ]; then
            exec ~/.local/bin/satty --filename "$TEMP_FILE" --output-filename "$DIR/Screenshot_%Y-%m-%d_%H-%M-%S_annotated.png"
        else
            GEOM=$(slurp -d -b "#00000088" -c "#ffffff" -w 2 2>/dev/null)
            [ -z "$GEOM" ] && exit 0
            grim -g "$GEOM" "$FILE"
            exec ~/.local/bin/satty --filename "$FILE" --output-filename "$DIR/Screenshot_%Y-%m-%d_%H-%M-%S_annotated.png"
        fi
        ;;
    *)
        grim "$FILE"
        ;;
esac

if [ ! -f "$FILE" ] || [ ! -s "$FILE" ]; then
    exit 0
fi

# Store a copy to temporary path for quick reference
cp "$FILE" "$TEMP_FILE"

# Automatically copy screenshot to clipboard
wl-copy --type image/png < "$FILE"
if command -v cliphist >/dev/null 2>&1; then
    cliphist store < "$FILE"
fi

# Send notification in background; clicking notification opens Satty annotation editor
(
    ACTION=$(notify-send \
        -a "Satty" \
        -i "$FILE" \
        -u normal \
        -A "default=Open in Satty" \
        -A "edit=Annotate" \
        "Screenshot Captured" \
        "Copied to clipboard & saved to $(basename "$FILE")")

    if [ "$ACTION" = "default" ] || [ "$ACTION" = "edit" ] || [ "$ACTION" = "0" ] || [ "$ACTION" = "1" ]; then
        ~/.local/bin/satty --filename "$FILE" --output-filename "$DIR/Screenshot_%Y-%m-%d_%H-%M-%S_annotated.png"
    fi
) &

exit 0

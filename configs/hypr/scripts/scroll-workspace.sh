#!/usr/bin/env bash

# Sequential Smooth Workspace Scrolling Traversal for Hyprland
# When jumping e.g. from 1 to 5, rapidly steps through 2 -> 3 -> 4 -> 5
# so all intermediate active windows are rendered scrolling horizontally.

TARGET="$1"

if [ -z "$TARGET" ]; then
    exit 0
fi

# Fetch current active workspace ID (JSON with regex fallback)
CURRENT=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null)
if [ -z "$CURRENT" ] || ! [[ "$CURRENT" =~ ^-?[0-9]+$ ]]; then
    CURRENT=$(hyprctl activeworkspace 2>/dev/null | grep -oP 'workspace ID \K[0-9]+' | head -n1)
fi

# If unable to determine or if already on target workspace
if [ -z "$CURRENT" ] || [ "$CURRENT" -eq "$TARGET" ]; then
    exit 0
fi

# Ignore or directly jump if coming from a special scratchpad workspace (ID < 1)
if [ "$CURRENT" -lt 1 ]; then
    hyprctl dispatch workspace "$TARGET"
    exit 0
fi

DIFF=$((TARGET - CURRENT))
ABS_DIFF=${DIFF#-}

# If direct adjacent workspace (e.g. 1 -> 2), direct dispatch
if [ "$ABS_DIFF" -le 1 ]; then
    hyprctl dispatch workspace "$TARGET"
    exit 0
fi

# Dynamic delay tuned for smooth chaining of Hyprland slide animation
if [ "$ABS_DIFF" -ge 6 ]; then
    DELAY=0.035
elif [ "$ABS_DIFF" -ge 4 ]; then
    DELAY=0.045
else
    DELAY=0.055
fi

# Forward traversal (e.g. 1 -> 5)
if [ "$TARGET" -gt "$CURRENT" ]; then
    for ((w = CURRENT + 1; w <= TARGET; w++)); do
        hyprctl dispatch workspace "$w"
        if [ "$w" -lt "$TARGET" ]; then
            sleep "$DELAY"
        fi
    done
# Backward traversal (e.g. 5 -> 1)
else
    for ((w = CURRENT - 1; w >= TARGET; w--)); do
        hyprctl dispatch workspace "$w"
        if [ "$w" -gt "$TARGET" ]; then
            sleep "$DELAY"
        fi
    done
fi

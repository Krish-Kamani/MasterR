#!/bin/sh
#
# SUPER+T full-fill toggle.
# Toggles active window between standard tiled layout and a full-filled floating
# window where all borders (top, bottom, left, right) remain perfectly visible
# inside the display boundaries, without hiding the pill or dock.

aw=$(hyprctl activewindow -j 2>/dev/null)
addr=$(printf '%s' "$aw" | jq -r '.address // ""')
[ -n "$addr" ] || exit 0

floating=$(printf '%s' "$aw" | jq -r '.floating')

if [ "$floating" = "true" ]; then
    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'off' }))" >/dev/null 2>&1
else
    # Query focused monitor geometry
    mon=$(hyprctl monitors -j | jq -r 'map(select(.focused)) | .[0] // .[0]')
    monW=$(printf '%s' "$mon" | jq -r '.width // 1920')
    monH=$(printf '%s' "$mon" | jq -r '.height // 1080')
    
    # 2px border padding on all 4 sides so borders are fully inside the screen
    border=2
    targetW=$((monW - border * 2))
    targetH=$((monH - border * 2))
    
    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'on' })) hl.dispatch(hl.dsp.window.resize({ x = $targetW, y = $targetH })) hl.dispatch(hl.dsp.window.move({ x = $border, y = $border }))" >/dev/null 2>&1
fi

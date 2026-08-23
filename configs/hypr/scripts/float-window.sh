#!/bin/sh
#
# SUPER+SHIFT+T independent floating window toggle.
# Toggles between tiled and a comfortable centered floating window (~1500x864 on 1080p).

aw=$(hyprctl activewindow -j 2>/dev/null)
addr=$(printf '%s' "$aw" | jq -r '.address // ""')
[ -n "$addr" ] || exit 0

floating=$(printf '%s' "$aw" | jq -r '.floating')
w=$(printf '%s' "$aw" | jq -r '.size[0] // 0')

# Query focused monitor geometry
mon=$(hyprctl monitors -j | jq -r 'map(select(.focused)) | .[0] // .[0]')
monW=$(printf '%s' "$mon" | jq -r '.width // 1920')
monH=$(printf '%s' "$mon" | jq -r '.height // 1080')

floatW=$((monW * 78 / 100))
floatH=$((monH * 80 / 100))

if [ "$floating" = "true" ]; then
    if [ "$w" -ge "$((monW - 10))" ]; then
        hyprctl eval "hl.dispatch(hl.dsp.window.resize({ x = $floatW, y = $floatH })) hl.dispatch(hl.dsp.window.center())" >/dev/null 2>&1
    else
        hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'off' }))" >/dev/null 2>&1
    fi
else
    hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'on' })) hl.dispatch(hl.dsp.window.resize({ x = $floatW, y = $floatH })) hl.dispatch(hl.dsp.window.center())" >/dev/null 2>&1
fi

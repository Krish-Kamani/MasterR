#!/bin/sh
#
# Toggle the focused window in and out of a special workspace. From a normal
# workspace the window drops into special:<name> silently; a window already in
# that special comes back to the monitor's active workspace and follows along, so
# one key both sends and retrieves. Bound per special (Super+Shift+S stash,
# Super+Shift+P private), the same shape Super+M uses for the minimized stash.

name="$1"
[ -n "$name" ] || exit 0

aw=$(hyprctl activewindow -j 2>/dev/null)
addr=$(printf '%s' "$aw" | jq -r '.address // ""')
ws=$(printf '%s' "$aw" | jq -r '.workspace.name // ""')
[ -n "$addr" ] || exit 0

if [ "$ws" = "special:$name" ]; then
	real=$(hyprctl monitors -j | jq -r 'map(select(.focused)) | .[0].activeWorkspace.id // 1')
	hyprctl dispatch "hl.dsp.window.move({ workspace = $real, window = \"address:$addr\" })" >/dev/null
else
	hyprctl dispatch "hl.dsp.window.move({ workspace = \"special:$name\", follow = false, window = \"address:$addr\" })" >/dev/null
fi

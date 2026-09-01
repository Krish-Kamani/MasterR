#!/usr/bin/env bash
#
# Toggle script for Liquid Glass effect in Hyprland
# Usage: liquid-glass.sh [on|off|toggle]
#

set -euo pipefail

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
GHOSTTY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"

update_flags() {
    local opacity="$1"
    local blur="$2"
    for dir in "${XDG_STATE_HOME:-$HOME/.local/state}/masterr" "${XDG_STATE_HOME:-$HOME/.local/state}/ricelin"; do
        local f="$dir/flags.json"
        if [ -f "$f" ]; then
            if command -v jq >/dev/null 2>&1; then
                jq --argjson op "$opacity" --argjson bl "$blur" '.pillOpacity = $op | .pillBlur = $bl' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
            fi
        fi
    done
}

turn_on() {
    if [ -f "$HYPR_DIR/modules/decoration.lua.glass" ]; then
        cp "$HYPR_DIR/modules/decoration.lua.glass" "$HYPR_DIR/modules/decoration.lua"
    fi
    if [ -f "$HYPR_DIR/modules/window_rules.lua.glass" ]; then
        cp "$HYPR_DIR/modules/window_rules.lua.glass" "$HYPR_DIR/modules/window_rules.lua"
    fi
    if [ -f "$GHOSTTY_CONF" ]; then
        sed -i 's/^background-opacity = .*/background-opacity = 0.70/' "$GHOSTTY_CONF"
    fi
    update_flags 0.25 true
    hyprctl reload >/dev/null 2>&1 || true
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Liquid Glass" "✨ Glass Effect Enabled" -i preferences-desktop-theme -t 1500 || true
    fi
}

turn_off() {
    if [ -f "$HYPR_DIR/modules/decoration.lua.solid" ]; then
        cp "$HYPR_DIR/modules/decoration.lua.solid" "$HYPR_DIR/modules/decoration.lua"
    fi
    if [ -f "$HYPR_DIR/modules/window_rules.lua.solid" ]; then
        cp "$HYPR_DIR/modules/window_rules.lua.solid" "$HYPR_DIR/modules/window_rules.lua"
    fi
    if [ -f "$GHOSTTY_CONF" ]; then
        sed -i 's/^background-opacity = .*/background-opacity = 1.00/' "$GHOSTTY_CONF"
    fi
    update_flags 1.0 false
    hyprctl reload >/dev/null 2>&1 || true
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Liquid Glass" "Solid Mode (Glass Disabled)" -i preferences-desktop-theme -t 1500 || true
    fi
}

is_on() {
    if grep -q "glass-all" "$HYPR_DIR/modules/window_rules.lua" 2>/dev/null; then
        return 0
    fi
    return 1
}

case "${1:-toggle}" in
    on)
        turn_on
        ;;
    off)
        turn_off
        ;;
    toggle)
        if is_on; then
            turn_off
        else
            turn_on
        fi
        ;;
    *)
        echo "Usage: $0 [on|off|toggle]" >&2
        exit 1
        ;;
esac

#!/usr/bin/env python3
"""
Hyprland Configuration Manager for MasterR.
Applies settings dynamically via `hyprctl eval` and persists them to decoration.lua, input.lua, and animations.lua.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "hypr" / "modules"
REPO_CONFIG_DIR = Path.home() / "MasterR" / "configs" / "hypr" / "modules"

DECORATION_FILE = CONFIG_DIR / "decoration.lua"
REPO_DECORATION_FILE = REPO_CONFIG_DIR / "decoration.lua"

INPUT_FILE = CONFIG_DIR / "input.lua"
REPO_INPUT_FILE = REPO_CONFIG_DIR / "input.lua"

ANIMATIONS_FILE = CONFIG_DIR / "animations.lua"
REPO_ANIMATIONS_FILE = REPO_CONFIG_DIR / "animations.lua"


def get_option_val(opt_name):
    try:
        out = subprocess.check_output(["hyprctl", "getoption", opt_name, "-j"], stderr=subprocess.DEVNULL)
        data = json.loads(out)
        if "float" in data:
            return data["float"]
        if "int" in data:
            return data["int"]
        if "bool" in data:
            return data["bool"]
        if "str" in data:
            return data["str"]
        if "css" in data:
            parts = data["css"].strip().split()
            if parts:
                return int(parts[0])
    except Exception:
        pass
    return None


def eval_hypr(lua_code):
    cmd = ["hyprctl", "eval", lua_code]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True)
        return res.returncode == 0
    except Exception as e:
        print(f"Error evaluating Hyprland config: {e}", file=sys.stderr)
        return False


# --- Decoration Settings ---

def get_current_settings():
    settings = {
        "active_opacity": get_option_val("decoration:active_opacity") or 0.90,
        "inactive_opacity": get_option_val("decoration:inactive_opacity") or 0.65,
        "rounding": get_option_val("decoration:rounding") or 16,
        "border_size": get_option_val("general:border_size") or 2,
        "gaps_in": get_option_val("general:gaps_in") or 8,
        "gaps_out": get_option_val("general:gaps_out") or 16,
        "layout": get_option_val("general:layout") or "dwindle",
        "blur_enabled": get_option_val("decoration:blur:enabled") if get_option_val("decoration:blur:enabled") is not None else True,
        "blur_size": get_option_val("decoration:blur:size") or 5,
        "blur_passes": get_option_val("decoration:blur:passes") or 2,
        "shadow_enabled": get_option_val("decoration:shadow:enabled") if get_option_val("decoration:shadow:enabled") is not None else True,
        "shadow_range": get_option_val("decoration:shadow:range") or 24,
    }
    return settings


def persist_setting(key, val):
    files_to_update = [DECORATION_FILE]
    if REPO_DECORATION_FILE.is_file():
        files_to_update.append(REPO_DECORATION_FILE)

    for target_file in files_to_update:
        if not target_file.is_file():
            continue
        try:
            content = target_file.read_text(encoding="utf-8")
            
            if key == "active_opacity":
                content = re.sub(r'\bactive_opacity\s*=\s*[\d\.]+', f'active_opacity   = {float(val):.2f}', content)
            elif key == "inactive_opacity":
                content = re.sub(r'inactive_opacity\s*=\s*[\d\.]+', f'inactive_opacity = {float(val):.2f}', content)
            elif key == "rounding":
                content = re.sub(r'rounding\s*=\s*\d+', f'rounding         = {int(val)}', content)
            elif key == "border_size":
                content = re.sub(r'border_size\s*=\s*\d+', f'border_size      = {int(val)}', content)
            elif key == "gaps_in":
                content = re.sub(r'gaps_in\s*=\s*\d+', f'gaps_in          = {int(val)}', content)
            elif key == "gaps_out":
                content = re.sub(r'gaps_out\s*=\s*\d+', f'gaps_out         = {int(val)}', content)
            elif key == "layout":
                content = re.sub(r'layout\s*=\s*"[^"]+"', f'layout           = "{val}"', content)
            elif key == "blur_size":
                content = re.sub(r'(blur\s*=\s*\{[\s\S]*?size\s*=\s*)\d+', rf'\g<1>{int(val)}', content)
            elif key == "blur_passes":
                content = re.sub(r'(blur\s*=\s*\{[\s\S]*?passes\s*=\s*)\d+', rf'\g<1>{int(val)}', content)
            elif key == "blur_enabled":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                content = re.sub(r'(blur\s*=\s*\{[\s\S]*?enabled\s*=\s*)(?:true|false)', rf'\g<1>{bool_str}', content)
            elif key == "shadow_enabled":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                content = re.sub(r'(shadow\s*=\s*\{[\s\S]*?enabled\s*=\s*)(?:true|false)', rf'\g<1>{bool_str}', content)
            elif key == "shadow_range":
                content = re.sub(r'(shadow\s*=\s*\{[\s\S]*?range\s*=\s*)\d+', rf'\g<1>{int(val)}', content)
            
            target_file.write_text(content, encoding="utf-8")
        except Exception as e:
            print(f"Failed to persist {key} in {target_file}: {e}", file=sys.stderr)


def apply_setting(key, val):
    lua_stmt = None

    if key == "active_opacity":
        fval = float(val)
        lua_stmt = f"hl.config({{ decoration = {{ active_opacity = {fval:.2f} }} }})"
    elif key == "inactive_opacity":
        fval = float(val)
        lua_stmt = f"hl.config({{ decoration = {{ inactive_opacity = {fval:.2f} }} }})"
    elif key == "rounding":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ decoration = {{ rounding = {ival} }} }})"
    elif key == "border_size":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ general = {{ border_size = {ival} }} }})"
    elif key == "gaps_in":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ general = {{ gaps_in = {ival} }} }})"
    elif key == "gaps_out":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ general = {{ gaps_out = {ival} }} }})"
    elif key == "layout":
        lua_stmt = f'hl.config({{ general = {{ layout = "{val}" }} }})'
    elif key == "blur_enabled":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ decoration = {{ blur = {{ enabled = {bval} }} }} }})"
    elif key == "blur_size":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ decoration = {{ blur = {{ size = {ival} }} }} }})"
    elif key == "blur_passes":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ decoration = {{ blur = {{ passes = {ival} }} }} }})"
    elif key == "shadow_enabled":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ decoration = {{ shadow = {{ enabled = {bval} }} }} }})"
    elif key == "shadow_range":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ decoration = {{ shadow = {{ range = {ival} }} }} }})"

    if lua_stmt:
        eval_hypr(lua_stmt)
    
    persist_setting(key, val)


# --- Input Settings ---

def get_current_input_settings():
    sens = get_option_val("input:sensitivity")
    accel = get_option_val("input:accel_profile")
    nat = get_option_val("input:touchpad:natural_scroll")
    left = get_option_val("input:left_handed")
    tap = get_option_val("input:touchpad:tap-to-click")
    drag = get_option_val("input:touchpad:tap-and-drag")
    dwt = get_option_val("input:touchpad:disable_while_typing")
    rate = get_option_val("input:repeat_rate")
    delay = get_option_val("input:repeat_delay")

    return {
        "sensitivity": float(sens) if sens is not None else 0.0,
        "accel_profile": str(accel) if accel else "flat",
        "natural_scroll": bool(nat) if nat is not None else True,
        "left_handed": bool(left) if left is not None else False,
        "tap_to_click": bool(tap) if tap is not None else True,
        "tap_and_drag": bool(drag) if drag is not None else True,
        "disable_while_typing": bool(dwt) if dwt is not None else True,
        "repeat_rate": int(rate) if rate is not None else 40,
        "repeat_delay": int(delay) if delay is not None else 400,
    }


def persist_input_setting(key, val):
    files_to_update = [INPUT_FILE]
    if REPO_INPUT_FILE.is_file():
        files_to_update.append(REPO_INPUT_FILE)

    for target_file in files_to_update:
        if not target_file.is_file():
            continue
        try:
            content = target_file.read_text(encoding="utf-8")
            
            if key == "sensitivity":
                content = re.sub(r'sensitivity\s*=\s*[-\d\.]+', f'sensitivity        = {float(val):.2f}', content)
            elif key == "accel_profile":
                content = re.sub(r'accel_profile\s*=\s*"[^"]+"', f'accel_profile      = "{val}"', content)
            elif key == "repeat_rate":
                content = re.sub(r'repeat_rate\s*=\s*\d+', f'repeat_rate        = {int(val)}', content)
            elif key == "repeat_delay":
                content = re.sub(r'repeat_delay\s*=\s*\d+', f'repeat_delay       = {int(val)}', content)
            elif key == "natural_scroll":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                content = re.sub(r'natural_scroll\s*=\s*(?:true|false)', f'natural_scroll = {bool_str}', content)
            elif key == "tap_to_click":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                content = re.sub(r'tap_to_click\s*=\s*(?:true|false)', f'tap_to_click   = {bool_str}', content)
            elif key == "left_handed":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                if "left_handed" in content:
                    content = re.sub(r'left_handed\s*=\s*(?:true|false)', f'left_handed        = {bool_str}', content)
                else:
                    content = re.sub(r'(input\s*=\s*\{)', rf'\g<1>\n        left_handed        = {bool_str},', content)
            elif key == "disable_while_typing":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                if "disable_while_typing" in content:
                    content = re.sub(r'disable_while_typing\s*=\s*(?:true|false)', f'disable_while_typing = {bool_str}', content)
                else:
                    content = re.sub(r'(touchpad\s*=\s*\{)', rf'\g<1>\n            disable_while_typing = {bool_str},', content)
            elif key == "tap_and_drag":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                if "tap_and_drag" in content:
                    content = re.sub(r'tap_and_drag\s*=\s*(?:true|false)', f'tap_and_drag = {bool_str}', content)
                else:
                    content = re.sub(r'(touchpad\s*=\s*\{)', rf'\g<1>\n            tap_and_drag = {bool_str},', content)
            
            target_file.write_text(content, encoding="utf-8")
        except Exception as e:
            print(f"Failed to persist input setting {key} in {target_file}: {e}", file=sys.stderr)


def apply_input_setting(key, val):
    lua_stmt = None

    if key == "sensitivity":
        fval = float(val)
        lua_stmt = f"hl.config({{ input = {{ sensitivity = {fval:.2f} }} }})"
    elif key == "accel_profile":
        lua_stmt = f'hl.config({{ input = {{ accel_profile = "{val}" }} }})'
    elif key == "natural_scroll":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ input = {{ touchpad = {{ natural_scroll = {bval} }} }} }})"
    elif key == "left_handed":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ input = {{ left_handed = {bval} }} }})"
    elif key == "tap_to_click":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ input = {{ touchpad = {{ tap_to_click = {bval} }} }} }})"
    elif key == "tap_and_drag":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ input = {{ touchpad = {{ tap_and_drag = {bval} }} }} }})"
    elif key == "disable_while_typing":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        lua_stmt = f"hl.config({{ input = {{ touchpad = {{ disable_while_typing = {bval} }} }} }})"
    elif key == "repeat_rate":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ input = {{ repeat_rate = {ival} }} }})"
    elif key == "repeat_delay":
        ival = int(round(float(val)))
        lua_stmt = f"hl.config({{ input = {{ repeat_delay = {ival} }} }})"

    if lua_stmt:
        eval_hypr(lua_stmt)
    
    persist_input_setting(key, val)


# --- Animation Settings ---

def persist_animation_setting(key, val):
    files_to_update = [ANIMATIONS_FILE]
    if REPO_ANIMATIONS_FILE.is_file():
        files_to_update.append(REPO_ANIMATIONS_FILE)

    for target_file in files_to_update:
        if not target_file.is_file():
            continue
        try:
            content = target_file.read_text(encoding="utf-8")
            if key == "enabled":
                bool_str = "true" if str(val).lower() in ("true", "1", "yes") else "false"
                content = re.sub(r'(animations\s*=\s*\{[\s\S]*?enabled\s*=\s*)(?:true|false)', rf'\g<1>{bool_str}', content)
            elif key == "speed":
                fval = float(val)
                content = re.sub(r'(leaf\s*=\s*"global"[\s\S]*?speed\s*=\s*)[\d\.]+', rf'\g<1>{fval:.1f}', content)
            target_file.write_text(content, encoding="utf-8")
        except Exception as e:
            print(f"Failed to persist animation setting {key} in {target_file}: {e}", file=sys.stderr)


def apply_animation_setting(key, val):
    if key == "enabled":
        bval = "true" if str(val).lower() in ("true", "1", "yes") else "false"
        eval_hypr(f"hl.config({{ animations = {{ enabled = {bval} }} }})")
        persist_animation_setting("enabled", bval)
    elif key == "speed":
        fval = float(val)
        eval_hypr(f'hl.animation({{ leaf = "global", enabled = true, speed = {fval:.1f}, bezier = "smoothOut" }})')
        eval_hypr(f'hl.animation({{ leaf = "windows", enabled = true, speed = {fval:.1f}, bezier = "smoothSpring" }})')
        eval_hypr(f'hl.animation({{ leaf = "workspaces", enabled = true, speed = {fval:.1f}, bezier = "fluidDecel", style = "slide" }})')
        persist_animation_setting("speed", fval)
    elif key == "preset":
        presets = {
            "spunky": ('hl.curve("smoothSpring", { type = "bezier", points = { { 0.05, 0.95 }, { 0.15, 1.02 } } })', 2.8),
            "fluidSpring": ('hl.curve("smoothSpring", { type = "bezier", points = { { 0.12, 0.98 }, { 0.22, 1.00 } } })', 3.0),
            "smoothFade": ('hl.curve("smoothSpring", { type = "bezier", points = { { 0.25, 1.00 }, { 0.50, 1.00 } } })', 2.4),
            "bouncy": ('hl.curve("smoothSpring", { type = "bezier", points = { { 0.15, 1.15 }, { 0.25, 1.05 } } })', 3.2),
            "snappy": ('hl.curve("smoothSpring", { type = "bezier", points = { { 0.20, 0.00 }, { 0.00, 1.00 } } })', 1.8),
        }
        if val in presets:
            curve_lua, spd = presets[val]
            eval_hypr(curve_lua)
            eval_hypr(f'hl.animation({{ leaf = "windows", enabled = true, speed = {spd}, bezier = "smoothSpring" }})')
            eval_hypr(f'hl.animation({{ leaf = "windowsIn", enabled = true, speed = {spd}, bezier = "smoothSpring", style = "popin 88%" }})')
            eval_hypr(f'hl.animation({{ leaf = "windowsOut", enabled = true, speed = {spd * 0.8:.1f}, bezier = "smoothOut", style = "popin 92%" }})')


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "get":
        print(json.dumps(get_current_settings(), indent=2))
    elif sys.argv[1] == "set" and len(sys.argv) >= 4:
        key = sys.argv[2]
        val = sys.argv[3]
        apply_setting(key, val)
        print("OK")
    elif sys.argv[1] == "get-input":
        print(json.dumps(get_current_input_settings(), indent=2))
    elif sys.argv[1] == "set-input" and len(sys.argv) >= 4:
        key = sys.argv[2]
        val = sys.argv[3]
        apply_input_setting(key, val)
        print("OK")
    elif sys.argv[1] == "set-anim" and len(sys.argv) >= 4:
        key = sys.argv[2]
        val = sys.argv[3]
        apply_animation_setting(key, val)
        print("OK")
    else:
        print("Usage: hypr-config.py [get | set <key> <val> | get-input | set-input <key> <val> | set-anim <key> <val>]")

if __name__ == "__main__":
    main()

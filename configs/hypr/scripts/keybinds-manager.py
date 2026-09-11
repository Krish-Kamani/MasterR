#!/usr/bin/env python3
"""
Keybinds Manager for MasterR / Hyprland (binds.lua).
Parses keybindings, exports JSON for the Settings UI, and updates binds.lua.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

BINDS_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "hypr" / "modules" / "binds.lua"
REPO_BINDS_CANDIDATES = [
    Path.home() / "DEV" / "Masterr-Repo" / "configs" / "hypr" / "modules" / "binds.lua",
    Path.home() / "MasterR" / "configs" / "hypr" / "modules" / "binds.lua",
    Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "masterr" / "configs" / "hypr" / "modules" / "binds.lua",
]
REPO_BINDS_PATH = next((p for p in REPO_BINDS_CANDIDATES if p.is_file()), REPO_BINDS_CANDIDATES[0])

def format_bind_line(key, action, category="Custom", description=""):
    clean_key = key.strip()
    if "SUPER" in clean_key.upper():
        parts = [p.strip() for p in re.split(r'\s*\+\s*', clean_key, flags=re.IGNORECASE) if p.strip()]
        mod_parts = []
        has_super = False
        for p in parts:
            if p.upper() == "SUPER":
                has_super = True
            else:
                mod_parts.append(p)
        if has_super and mod_parts:
            key_expr = f'mod .. " + {" + ".join(mod_parts)}"'
        elif has_super:
            key_expr = 'mod'
        else:
            key_expr = f'"{clean_key}"'
    else:
        key_expr = f'"{clean_key}"'

    clean_action = action.strip()
    if clean_action.startswith("hl.dsp."):
        action_expr = clean_action
    else:
        escaped_cmd = clean_action.replace('"', '\\"')
        action_expr = f'hl.dsp.exec_cmd("{escaped_cmd}")'

    cat = (category or "Custom").strip()
    desc = (description or clean_key).strip()
    
    return f'hl.bind({key_expr}, {action_expr}) -- [{cat}] {desc}'

def parse_binds():
    if not BINDS_PATH.is_file():
        return []
    
    binds = []
    content = BINDS_PATH.read_text(encoding="utf-8")
    lines = content.splitlines()

    pattern = re.compile(
        r'hl\.bind\(\s*(.*?)\s*,\s*(.*?)\s*(?:,\s*(\{.*?\}))?\s*\)\s*(?:--\s*(?:\[(.*?)\])?\s*(.*))?$'
    )

    for line_idx, line in enumerate(lines):
        line_s = line.strip()
        if not line_s.startswith("hl.bind"):
            continue
        m = pattern.match(line_s)
        if m:
            raw_key, raw_action, raw_opts, category, desc = m.groups()
            key = raw_key.replace('mod .. "', 'SUPER').replace('"', '').replace(' .. ', ' ').strip()
            cat = (category or "General").strip()
            description = (desc or "").strip()
            
            clean_cmd = raw_action.strip()
            cmd_m = re.match(r'hl\.dsp\.exec_cmd\((?:os\.getenv\("HOME"\)\s*\.\.\s*)?"(.*?)"\)', clean_cmd)
            if cmd_m:
                disp_cmd = cmd_m.group(1)
            else:
                disp_cmd = clean_cmd
            
            binds.append({
                "line": line_idx + 1,
                "key": key,
                "action": clean_cmd,
                "command": disp_cmd,
                "opts": (raw_opts or "").strip(),
                "category": cat,
                "description": description or key,
                "raw": line_s
            })
    return binds

def list_binds():
    binds = parse_binds()
    print(json.dumps(binds, indent=2))

def sync_binds_content(content):
    BINDS_PATH.write_text(content, encoding="utf-8")
    if REPO_BINDS_PATH.is_file():
        REPO_BINDS_PATH.write_text(content, encoding="utf-8")
    subprocess.run(["hyprctl", "reload"], capture_output=True)

def add_bind(key, command, category="Custom", description=""):
    if not BINDS_PATH.is_file():
        return False
    
    content = BINDS_PATH.read_text(encoding="utf-8")
    new_line = format_bind_line(key, command, category, description)
    
    content = content.rstrip() + "\n" + new_line + "\n"
    sync_binds_content(content)
    return True

def edit_bind(line_num, key, command, category="Custom", description=""):
    if not BINDS_PATH.is_file():
        return False
    
    content = BINDS_PATH.read_text(encoding="utf-8")
    lines = content.splitlines()
    
    idx = int(line_num) - 1
    if 0 <= idx < len(lines):
        new_line = format_bind_line(key, command, category, description)
        lines[idx] = new_line
        new_content = "\n".join(lines) + "\n"
        sync_binds_content(new_content)
        return True
    return False

def remove_bind(line_num):
    if not BINDS_PATH.is_file():
        return False
    
    content = BINDS_PATH.read_text(encoding="utf-8")
    lines = content.splitlines()
    
    idx = int(line_num) - 1
    if 0 <= idx < len(lines):
        del lines[idx]
        new_content = "\n".join(lines) + "\n"
        sync_binds_content(new_content)
        return True
    return False

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "--list":
        list_binds()
    elif sys.argv[1] == "--add" and len(sys.argv) >= 4:
        key = sys.argv[2]
        cmd = sys.argv[3]
        cat = sys.argv[4] if len(sys.argv) > 4 else "Custom"
        desc = sys.argv[5] if len(sys.argv) > 5 else ""
        add_bind(key, cmd, cat, desc)
        print("OK")
    elif sys.argv[1] == "--edit" and len(sys.argv) >= 5:
        line_num = int(sys.argv[2])
        key = sys.argv[3]
        cmd = sys.argv[4]
        cat = sys.argv[5] if len(sys.argv) > 5 else "Custom"
        desc = sys.argv[6] if len(sys.argv) > 6 else ""
        if edit_bind(line_num, key, cmd, cat, desc):
            print("OK")
        else:
            print("ERROR: Invalid line", file=sys.stderr)
            sys.exit(1)
    elif sys.argv[1] == "--remove" and len(sys.argv) >= 3:
        line_num = int(sys.argv[2])
        if remove_bind(line_num):
            print("OK")
        else:
            print("ERROR: Invalid line", file=sys.stderr)
            sys.exit(1)
    else:
        print("Usage: keybinds-manager.py [--list | --add <k> <c> [cat] [desc] | --edit <line> <k> <c> [cat] [desc] | --remove <line>]")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Fast file & folder finder backend for Quickshell / MasterR.
Searches $HOME with multi-tier relevance ranking and outputs JSON.
- By default (empty query): hidden files and directories are hidden.
- When searched (query entered): includes hidden files and directories.
"""

import os
import sys
import json

HOME = os.path.expanduser("~")

# Directories to skip completely to keep search instant and avoid cache bloat
IGNORE_DIRS = {
    ".git", "node_modules", ".cache", ".npm", ".cargo", ".rustup",
    ".nv", "__pycache__", ".gemini", "yay-bin",
    ".android", ".gradle", ".idea", ".vscode", ".electron",
    ".var", "build", "dist", "target", ".venv", "venv",
    ".wine", ".steam", "Trash", ".Trash"
}

def get_match_score(name: str, q: str) -> int:
    name_lower = name.lower()
    name_clean = name_lower.lstrip(".")
    
    # Exact match
    if name_lower == q or name_clean == q:
        return 0
    # Prefix match
    if name_lower.startswith(q) or name_clean.startswith(q):
        return 1
    # Substring match
    if q in name_lower or q in name_clean:
        return 2
    
    # Subsequence match only for queries of 3+ chars
    if len(q) >= 3:
        j = 0
        q_len = len(q)
        for ch in name_lower:
            if ch == q[j]:
                j += 1
                if j == q_len:
                    return 3
    
    return 99

def search(query: str = "", limit: int = 60):
    q = query.strip().lower()
    
    # When query is empty: list top-level visible directories and files (hidden files excluded by default)
    if not q:
        results = []
        try:
            with os.scandir(HOME) as it:
                entries = []
                for entry in it:
                    if entry.name.startswith("."):
                        continue
                    try:
                        is_dir = entry.is_dir(follow_symlinks=False)
                        st = entry.stat(follow_symlinks=False)
                        entries.append((is_dir, entry.name, entry.path, st.st_mtime))
                    except OSError:
                        pass
                
                # Sort: directories first, then alphabetically
                entries.sort(key=lambda x: (not x[0], x[1].lower()))
                for is_dir, name, full_path, mtime in entries:
                    ext = "" if is_dir else os.path.splitext(name)[1].lstrip(".").lower()
                    results.append({
                        "name": name,
                        "path": full_path,
                        "isDir": is_dir,
                        "ext": ext,
                        "parent": "~"
                    })
        except Exception:
            pass
        return results[:limit]

    # When query is provided: search across all files and folders, INCLUDING hidden files and directories
    scored = []
    count = 0
    max_scan = 50000

    for root, dirs, files in os.walk(HOME):
        # Filter directories in-place (exclude heavy cache/build dirs, but allow hidden user config dirs like .config)
        dirs[:] = [
            d for d in dirs
            if d not in IGNORE_DIRS and not d.endswith(".tmp")
        ]

        rel_root = os.path.relpath(root, HOME)
        parent_disp = "~" if rel_root == "." else f"~/{rel_root}"

        for d in dirs:
            count += 1
            s = get_match_score(d, q)
            if s < 99:
                full_path = os.path.join(root, d)
                scored.append((s, False, d, full_path, "", parent_disp))

        for f in files:
            count += 1
            if f.endswith(".tmp") or f.endswith(".swp"):
                continue
            s = get_match_score(f, q)
            if s < 99:
                full_path = os.path.join(root, f)
                ext = os.path.splitext(f)[1].lstrip(".").lower()
                scored.append((s, True, f, full_path, ext, parent_disp))

        if count >= max_scan:
            break

    # Sort: best score first, then folders before files for equal score, then alphabetical
    scored.sort(key=lambda item: (item[0], item[1], item[2].lower()))

    out = []
    for s, is_file, name, full_path, ext, parent_disp in scored[:limit]:
        out.append({
            "name": name,
            "path": full_path,
            "isDir": not is_file,
            "ext": ext,
            "parent": parent_disp
        })
    return out

def main():
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    results = search(query, limit=60)
    print(json.dumps(results))

if __name__ == "__main__":
    main()

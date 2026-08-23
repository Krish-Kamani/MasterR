#!/usr/bin/env python3
"""
Comprehensive package search helper for Quickshell / MasterR.
Searches all packages across Official Arch Repositories (OAR) via pacman
and Arch User Repositories (AUR) via the AUR RPC API.
Includes all available software (installed and non-installed).
"""

import sys
import json
import subprocess
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor

def get_installed_packages():
    try:
        p = subprocess.run(["pacman", "-Qq"], capture_output=True, text=True, timeout=2)
        return set(p.stdout.splitlines())
    except Exception:
        return set()

def search_pacman(q, installed_set):
    results = []
    try:
        p = subprocess.run(["pacman", "-Ss", q], capture_output=True, text=True, timeout=3)
        lines = p.stdout.strip().split("\n")
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if not line:
                i += 1
                continue
            if "/" in line:
                parts = line.split()
                repo_parts = parts[0].split("/")
                repo = repo_parts[0]
                name = repo_parts[1]
                version = parts[1] if len(parts) > 1 else ""
                is_installed = "[installed]" in line or name in installed_set
                desc = lines[i+1].strip() if i+1 < len(lines) else ""
                results.append({
                    "name": name,
                    "source": "OAR",
                    "repo": repo,
                    "version": version,
                    "desc": desc,
                    "installed": is_installed,
                    "votes": 0,
                    "popularity": 0.0
                })
                i += 2
            else:
                i += 1
    except Exception:
        pass
    return results

def search_aur(q, installed_set):
    results = []
    try:
        url = "https://aur.archlinux.org/rpc/v5/search/" + urllib.parse.quote(q)
        req = urllib.request.Request(url, headers={"User-Agent": "MasterR-PkgFinder/1.0"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            for r in data.get("results", []):
                name = r.get("Name", "")
                results.append({
                    "name": name,
                    "source": "AUR",
                    "repo": "aur",
                    "version": r.get("Version", ""),
                    "desc": r.get("Description", "") or "",
                    "installed": name in installed_set,
                    "votes": r.get("NumVotes", 0),
                    "popularity": r.get("Popularity", 0.0)
                })
    except Exception:
        pass
    return results

def get_default_packages(installed_set):
    """Extensive catalog of popular available software across OAR and AUR when search query is empty."""
    catalog = [
        # Web Browsers
        ("zen-browser-bin", "AUR", "aur", "Experience tranquillity while browsing the web (Firefox fork)"),
        ("brave-bin", "AUR", "aur", "Privacy-oriented browser with built-in ad blocking"),
        ("google-chrome", "AUR", "aur", "The popular web browser by Google"),
        ("thorium-browser-bin", "AUR", "aur", "The fastest browser on Earth - Chromium fork with compiler optimizations"),
        ("librewolf-bin", "AUR", "aur", "Community-maintained fork of Firefox focused on privacy and security"),
        ("floorp-bin", "AUR", "aur", "A feature-rich, privacy-conscious Firefox-based browser"),
        ("firefox", "OAR", "extra", "Fast, Private & Safe Web Browser"),
        ("chromium", "OAR", "extra", "Open-source web browser project behind Google Chrome"),

        # Development & Editors
        ("visual-studio-code-bin", "AUR", "aur", "Code editor redefined and optimized for modern web and cloud"),
        ("vscodium-bin", "AUR", "aur", "Free/Libre Open Source Software Binaries of VS Code"),
        ("cursor-bin", "AUR", "aur", "AI-powered code editor built on VS Code"),
        ("zed", "OAR", "extra", "High-performance, multiplayer code editor from the creators of Atom"),
        ("sublime-text-4", "AUR", "aur", "Sophisticated text editor for code, markup and prose"),
        ("neovim", "OAR", "extra", "Vim-fork focused on extensibility and usability"),
        ("jetbrains-toolbox", "AUR", "aur", "Manage JetBrains IDEs, Android Studio, and developer projects"),
        ("postman-bin", "AUR", "aur", "API platform for building and using APIs"),
        ("docker", "OAR", "extra", "Pack, ship and run any application as a lightweight container"),

        # Social & Communication
        ("vesktop-bin", "AUR", "aur", "Custom Discord App with Vencord plugins pre-installed"),
        ("discord", "OAR", "extra", "All-in-one voice and text chat for gamers"),
        ("telegram-desktop", "OAR", "extra", "Official Telegram Desktop messaging app"),
        ("signal-desktop", "OAR", "extra", "Private, secure messaging for desktop"),
        ("betterdiscord-installer", "AUR", "aur", "Installer for BetterDiscord desktop client"),

        # Media, Streaming & Creative
        ("spotify", "AUR", "aur", "Music streaming service client"),
        ("spicetify-cli", "AUR", "aur", "Command-line tool to customize Spotify client themes and extensions"),
        ("cider", "AUR", "aur", "Cross-platform Apple Music experience built on Electron and Vue.js"),
        ("obs-studio", "OAR", "extra", "Free and open source software for video recording and live streaming"),
        ("blender", "OAR", "extra", "Fully integrated 3D graphics creation suite"),
        ("kdenlive", "OAR", "extra", "Non-linear video editor for GNU/Linux"),
        ("krita", "OAR", "extra", "Digital painting software designed for illustrators and concept artists"),
        ("gimp", "OAR", "extra", "GNU Image Manipulation Program"),
        ("inkscape", "OAR", "extra", "Professional vector graphics editor"),
        ("mpv", "OAR", "extra", "Command line video player with broad format support"),
        ("vlc", "OAR", "extra", "Multi-platform media player and framework"),

        # Gaming & Emulation
        ("steam", "OAR", "multilib", "Valve's digital software delivery platform"),
        ("heroic-games-launcher-bin", "AUR", "aur", "Open-source games launcher for Epic Games, GOG and Amazon"),
        ("lutris", "OAR", "extra", "Open Source gaming platform for GNU/Linux"),
        ("prismlauncher", "OAR", "extra", "Custom Minecraft launcher that allows managing multiple instances"),
        ("retroarch", "OAR", "extra", "Frontend for emulators, game engines and media players"),

        # Utilities & System Monitoring
        ("btop", "OAR", "extra", "Resource monitor that shows usage and stats for processor, memory, disks and network"),
        ("fastfetch", "OAR", "extra", "Neofetch-like tool for fetching system information and displaying it prettily"),
        ("timeshift", "OAR", "extra", "System restore utility providing functionality similar to System Restore"),
        ("bleachbit", "OAR", "extra", "Cleans cache, deletes junk, and frees disk space"),
        ("peazip-bin", "AUR", "aur", "Free zip / rar / 7z archiver and file manager"),
        ("stacer-bin", "AUR", "aur", "Linux system optimizer and monitoring tool"),
        ("gparted", "OAR", "extra", "Partition editor for graphically managing your disk partitions"),
        ("cava", "OAR", "extra", "Console-based Audio Visualizer for ALSA, PulseAudio, and PipeWire"),
        ("easyeffects", "OAR", "extra", "Audio effects for PipeWire applications"),
        ("obsidian", "OAR", "extra", "Powerful and extensible knowledge base on top of local Markdown files")
    ]
    results = []
    for name, source, repo, desc in catalog:
        results.append({
            "name": name,
            "source": source,
            "repo": repo,
            "version": "",
            "desc": desc,
            "installed": name in installed_set,
            "votes": 100,
            "popularity": 1.0
        })
    return results

def search_all(query: str, limit: int = 100):
    q = query.strip().lower()
    installed_set = get_installed_packages()

    if not q:
        return get_default_packages(installed_set)

    with ThreadPoolExecutor(max_workers=2) as executor:
        future_pacman = executor.submit(search_pacman, q, installed_set)
        future_aur = executor.submit(search_aur, q, installed_set)
        oar_results = future_pacman.result()
        aur_results = future_aur.result()

    def rank_score(item):
        name = item["name"].lower()
        if name == q:
            s = 0  # Exact name match
        elif name.startswith(q):
            s = 1  # Prefix match
        elif q in name:
            s = 2  # Substring in name
        else:
            s = 3  # Other match (e.g. description)
        
        # OAR comes before AUR for identical score
        src_rank = 0 if item["source"] == "OAR" else 1
        # Higher votes/popularity prioritized
        votes = item.get("votes", 0)
        return (s, src_rank, -votes, name)

    combined = sorted(oar_results + aur_results, key=rank_score)
    return combined[:limit]

def main():
    query = sys.argv[1] if len(sys.argv) > 1 else ""
    results = search_all(query, limit=100)
    print(json.dumps(results))

if __name__ == "__main__":
    main()

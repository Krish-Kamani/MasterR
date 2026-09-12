#!/usr/bin/env bash

UA="Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/126.0"

search() {
    local query="${1:-}" kind="${2:-all}"
    [ -n "$query" ] || { printf '[]\n'; return 0; }

    UA="$UA" python3 - "$query" "$kind" <<'PYEOF'
import concurrent.futures
import json
import os
import re
import sys
import urllib.parse
import urllib.request

query = sys.argv[1].strip() if len(sys.argv) > 1 else ""
kind = sys.argv[2].strip() if len(sys.argv) > 2 else "all"

if not query:
    print("[]")
    sys.exit(0)

ua = os.environ.get("UA", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

def fetch(url, headers=None, timeout=6):
    h = {"User-Agent": ua}
    if headers:
        h.update(headers)
    req = urllib.request.Request(url, headers=h)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "ignore")

def search_wallhaven(q):
    try:
        url = f"https://wallhaven.cc/api/v1/search?q={urllib.parse.quote(q)}&sorting=relevance&purity=100"
        raw = fetch(url, timeout=5)
        data = json.loads(raw)
        out = []
        for item in data.get("data", []):
            p = item.get("path")
            if not p:
                continue
            thumbs = item.get("thumbs", {})
            t = thumbs.get("large") or thumbs.get("small") or p
            out.append({
                "image": p,
                "thumb": t,
                "w": item.get("dimension_x", 0),
                "h": item.get("dimension_y", 0),
            })
        return out
    except Exception:
        return []

def search_moewalls(q):
    def post_entry(url):
        try:
            html = fetch(url, headers={"Referer": "https://moewalls.com/"}, timeout=5)
            prev = re.search(r'<source[^>]+src="([^"]+)"', html)
            if not prev:
                prev = re.search(r'<video[^>]+src="([^"]+)"', html)
            token = re.search(r'id="moe-download"[^>]*data-url="([^"]+)"', html)
            thumb = re.search(r'poster="([^"]+)"', html)
            if not prev or not token:
                return None
            res = re.search(r'resolutions-(\d+)x(\d+)', html)
            if not res:
                res = re.search(r'(\d{3,4})\s*[x×]\s*(\d{3,4})', html)
            return {
                "image": "https://go.moewalls.com/download.php?video=" + token.group(1),
                "thumb": urllib.parse.urljoin("https://moewalls.com/", thumb.group(1)) if thumb else "",
                "preview": urllib.parse.urljoin("https://moewalls.com/", prev.group(1)),
                "w": int(res.group(1)) if res else 0,
                "h": int(res.group(2)) if res else 0,
            }
        except Exception:
            return None

    try:
        page = fetch("https://moewalls.com/?s=" + urllib.parse.quote(q), headers={"Referer": "https://moewalls.com/"}, timeout=6)
        posts = []
        for m in re.finditer(r'href="(https://moewalls\.com/(?!category|tag|resolution|author|page)[a-z0-9-]+/[a-z0-9-]+(?:-live-wallpaper)?/?)"', page):
            if m.group(1) not in posts:
                posts.append(m.group(1))
        out = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
            for entry in ex.map(post_entry, posts[:12]):
                if entry:
                    out.append(entry)
        return out
    except Exception:
        return []

def search_ddg(q, k):
    try:
        f = "type:photo" if k == "still" else ",,,"
        html = fetch(f"https://duckduckgo.com/?q={urllib.parse.quote(q)}&iax=images&ia=images", timeout=4)
        m = re.search(r'vqd="?([0-9-]+)', html)
        if not m:
            return []
        vqd = m.group(1)
        url2 = f"https://duckduckgo.com/i.js?l=us-en&o=json&q={urllib.parse.quote(q)}&vqd={vqd}&f={f}&p=-1"
        headers2 = {
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "Accept-Language": "en-US,en;q=0.9",
            "Referer": "https://duckduckgo.com/",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "X-Requested-With": "XMLHttpRequest"
        }
        raw = fetch(url2, headers=headers2, timeout=4)
        data = json.loads(raw)
        results = data.get("results", [])
        out = []
        for item in results:
            img = item.get("image")
            if not img:
                continue
            is_gif = bool(re.search(r'\.gif(\?|$)', img, re.I))
            if k == "motion" and not is_gif:
                continue
            if k == "still" and is_gif:
                continue
            out.append({
                "image": img,
                "thumb": item.get("thumbnail") or img,
                "w": item.get("width") or 0,
                "h": item.get("height") or 0
            })
        return out
    except Exception:
        return []

try:
    if kind == "motion":
        res = search_moewalls(query)
        if not res:
            res = search_ddg(query, "motion")
        print(json.dumps(res[:60]))
        sys.exit(0)

    if kind == "all":
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
            f_wh = ex.submit(search_wallhaven, query)
            f_moe = ex.submit(search_moewalls, query)
            wh = f_wh.result() or []
            moe = f_moe.result() or []

        combined = []
        seen = set()
        max_len = max(len(wh), len(moe))
        for i in range(max_len):
            if i < len(wh) and wh[i]["image"] not in seen:
                seen.add(wh[i]["image"])
                combined.append(wh[i])
            if i < len(moe) and moe[i]["image"] not in seen:
                seen.add(moe[i]["image"])
                combined.append(moe[i])

        if len(combined) < 12:
            ddg = search_ddg(query, "all")
            for item in ddg:
                if item["image"] not in seen:
                    seen.add(item["image"])
                    combined.append(item)

        print(json.dumps(combined[:60]))
        sys.exit(0)

    wh = search_wallhaven(query)
    seen = set(item["image"] for item in wh)
    if len(wh) < 12:
        ddg = search_ddg(query, "still")
        for item in ddg:
            if item["image"] not in seen:
                seen.add(item["image"])
                wh.append(item)

    print(json.dumps(wh[:60]))
except Exception:
    print("[]")
PYEOF
}

download() {
    set -euo pipefail
    url="${1:-}"
    [ -n "$url" ] || exit 1

    flags="${XDG_STATE_HOME:-$HOME/.local/state}/masterr/flags.json"
    wpdir=$(jq -r '.wallpaperDir // ""' "$flags" 2>/dev/null || echo "")
    if [ -z "$wpdir" ] || [ ! -d "$wpdir" ]; then
        for c in "$HOME/Pictures/Wallpapers" "$HOME/Pictures/wallpapers" "${XDG_DATA_HOME:-$HOME/.local/share}/masterr/wallpapers" "$HOME/DEV/Masterr-Repo/wallpapers" "$HOME/MasterR/wallpapers"; do
            if [ -d "$c" ]; then wpdir="$c"; break; fi
        done
    fi
    [ -n "$wpdir" ] || wpdir="$HOME/Pictures/Wallpapers"
    dir="$wpdir/downloads"
    mkdir -p "$dir"

    case "$url" in
        https://go.moewalls.com/download.php*|*moewalls.com/download.php*|*go.moewalls.com/*)
            headers=$(curl -fsIL --max-time 20 -A "$UA" -e "https://moewalls.com/" "$url" 2>/dev/null || true)
            fn=$(printf '%s\n' "$headers" | sed -En 's/.*filename="?([^";[:space:]]+)"?.*/\1/p' | head -1 | tr -d '/\\' || true)
            [ -n "$fn" ] || fn="moewalls-$(date +%s).mp4"
            case "$fn" in
                *.[Mm][Pp]4|*.[Ww][Ee][Bb][Mm]|*.[Mm][Kk][Vv]|*.[Mm][Oo][Vv]) ;;
                *) fn="${fn}.mp4" ;;
            esac
            out="$dir/$fn"
            tmp_dl="${out}.part.$$"
            curl -fsL --max-time 600 -A "$UA" -e "https://moewalls.com/" -o "$tmp_dl" "$url" || { rm -f "$tmp_dl"; exit 1; }
            [ -s "$tmp_dl" ] || { rm -f "$tmp_dl"; exit 1; }
            mv -f "$tmp_dl" "$out"
            printf '%s\n' "$out"
            exit 0
            ;;
    esac

    tmp=$(mktemp "${TMPDIR:-/tmp}/wp-dl.XXXXXX")
    trap 'rm -f "$tmp" "$tmp.out"' EXIT

    curl -fsL --max-time 600 -A "$UA" -o "$tmp" "$url" || exit 1
    [ -s "$tmp" ] || exit 1

    mime=$(file -b --mime-type "$tmp" 2>/dev/null || true)
    case "$mime" in
        video/mp4)        ext="mp4" ;;
        video/webm)       ext="webm" ;;
        video/x-matroska) ext="mkv" ;;
        video/quicktime)  ext="mov" ;;
        *)                ext="" ;;
    esac

    if [ -n "$ext" ]; then
        url_base=$(basename "${url%%\?*}" 2>/dev/null || true)
        if [[ "$url_base" =~ ^[a-zA-Z0-9_.-]+$ ]] && [[ "$url_base" == *.* ]]; then
            fn_base="${url_base%.*}"
            out="$dir/${fn_base}.${ext}"
        else
            out="$dir/live-$(date +%s)-${RANDOM}.${ext}"
        fi
        cp -f "$tmp" "$out"
        [ -s "$out" ] || exit 1
        printf '%s\n' "$out"
        exit 0
    fi

    export MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"

    fmt=$(magick identify -format '%m' "${tmp}[0]" 2>/dev/null | head -1 || true)
    [ -n "$fmt" ] || exit 1

    case "$fmt" in
        JPEG) ext=jpg ;;
        PNG)  ext=png ;;
        GIF)  ext=gif ;;
        WEBP) ext=webp ;;
        *)    ext=png ;;
    esac

    url_base=$(basename "${url%%\?*}" 2>/dev/null || true)
    if [[ "$url_base" =~ ^[a-zA-Z0-9_.-]+$ ]] && [[ "$url_base" == *.* ]]; then
        fn_base="${url_base%.*}"
        out="$dir/${fn_base}.${ext}"
    else
        out="$dir/wallpaper-$(date +%s)-${RANDOM}.${ext}"
    fi

    if [ "$ext" = "png" ] && [ "$fmt" != "PNG" ]; then
        magick "${tmp}[0]" -strip "png:$tmp.out" 2>/dev/null || exit 1
        [ -s "$tmp.out" ] || exit 1
        mv "$tmp.out" "$out"
    else
        cp "$tmp" "$out"
    fi

    [ -s "$out" ] || exit 1
    printf '%s\n' "$out"
}

case "${1:-}" in
    search)   search "${2:-}" "${3:-all}" ;;
    download) download "${2:-}" ;;
    *)        printf '[]\n'; exit 0 ;;
esac

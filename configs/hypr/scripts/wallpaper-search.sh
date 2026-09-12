#!/usr/bin/env bash

UA="Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/126.0"

search_moewalls() {
    local query="${1:-}"
    UA="$UA" python3 - "$query" <<'PYEOF'
import concurrent.futures
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ua = os.environ.get("UA", "Mozilla/5.0")

def fetch(url, timeout=10):
    req = urllib.request.Request(url, headers={"User-Agent": ua, "Referer": "https://moewalls.com/"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "ignore")

def post_entry(url):
    html = fetch(url)
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

try:
    q = urllib.parse.quote(sys.argv[1])
    page = fetch("https://moewalls.com/?s=" + q, timeout=12)
    posts = []
    for m in re.finditer(r'href="(https://moewalls\.com/(?!category|tag|resolution|author|page)[a-z0-9-]+/[a-z0-9-]+(?:-live-wallpaper)?/?)"', page):
        if m.group(1) not in posts:
            posts.append(m.group(1))
    out = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for entry in ex.map(post_entry, posts[:24]):
            if entry:
                out.append(entry)
    print(json.dumps(out))
except Exception:
    print("[]")
PYEOF
}

search() {
    local query="${1:-}" kind="${2:-all}"
    [ -n "$query" ] || { printf '[]\n'; return 0; }

    if [ "$kind" = "motion" ]; then
        local moe
        moe=$(search_moewalls "$query") || moe="[]"
        if [ "$moe" != "[]" ] && [ -n "$moe" ]; then
            printf '%s\n' "$moe"
            return 0
        fi
    fi

    local q="$query" f=",,,"
    case "$kind" in
        still)  f="type:photo" ;;
    esac

    local enc vqd raw
    enc=$(jq -rn --arg q "$q" '$q|@uri') || { printf '[]\n'; return 0; }

    vqd=$(curl -s --max-time 10 "https://duckduckgo.com/?q=${enc}&iax=images&ia=images" -A "$UA" \
        | grep -oP 'vqd=\\?"?\K[0-9-]+' | head -1)
    [ -n "$vqd" ] || { printf '[]\n'; return 0; }

    raw=$(curl -s --max-time 10 \
        "https://duckduckgo.com/i.js?l=us-en&o=json&q=${enc}&vqd=${vqd}&f=${f}&p=-1" \
        -A "$UA" -H "Referer: https://duckduckgo.com/")
    [ -n "$raw" ] || { printf '[]\n'; return 0; }

    printf '%s' "$raw" | jq -c --arg kind "$kind" '
        (.results // [])
        | if $kind == "motion" then map(select(.image // "" | test("\\.gif(\\?|$)"; "i")))
          elif $kind == "still" then map(select(.image // "" | test("\\.gif(\\?|$)"; "i") | not))
          else . end
        | map({
            image: .image,
            thumb: (.thumbnail // .image),
            w: (.width // 0 | if . == null then 0 else . end),
            h: (.height // 0 | if . == null then 0 else . end)
          })
        | map(select(.image != null and .image != ""))
        | .[0:60]
    ' 2>/dev/null || printf '[]\n'
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

    tmp=$(mktemp "${TMPDIR:-/tmp}/ddg-wp.XXXXXX")
    trap 'rm -f "$tmp" "$tmp.out"' EXIT

    curl -fsL --max-time 600 -A "$UA" -e "https://duckduckgo.com/" -o "$tmp" "$url" || exit 1
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
        if [[ "$url_base" == *.* && "$url_base" != *"="* ]]; then
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

    out="$dir/ddg-$(date +%s)-${RANDOM}.${ext}"

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

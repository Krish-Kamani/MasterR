#!/usr/bin/env python3
"""
Generate the rice colour set from a wallpaper and fan it out to the consumers.
One histogram pass yields both the area-dominant chromatic hue (binned by hue
family so a small vivid accent never hijacks the theme) and the mean lightness.
The mean lightness drives the pill's whole tone: a bright wallpaper makes a light
pill with dark text, a dark or OLED-black one makes a near-black pill with cream
text, so the surfaces and the text flip together for contrast across the full
range. The dominant hue tints every tier in HSL. An achromatic wallpaper drops to
a neutral grey ramp. matugen still builds the dark base16 the always-dark terminal
reads; the pill JSON carries surfaces, accent and the contrast-matched text.
"""
import colorsys
import json
import re
import subprocess
import sys
from pathlib import Path

CACHE = Path.home() / ".cache" / "masterr"

SURF_NAMES = ["surface", "surface_container_low", "surface_container",
              "surface_container_high", "surface_container_highest", "outline_variant"]
DARK_STEPS = [0.0, 0.022, 0.038, 0.065, 0.100, 0.225]
LIGHT_STEPS = [0.0, -0.045, -0.075, -0.115, -0.160, -0.340]
TEXT_KEYS = ["cream", "bright", "subtle", "dim", "faint", "icon_dim", "tick_rest"]
DARK_TEXT = [(0.90, 0.05), (0.97, 0.03), (0.73, 0.07), (0.54, 0.06),
             (0.44, 0.05), (0.81, 0.07), (0.75, 0.08)]
LIGHT_TEXT = [(0.20, 0.18), (0.10, 0.20), (0.36, 0.14), (0.48, 0.10),
              (0.56, 0.08), (0.28, 0.12), (0.34, 0.12)]


def analyze(wallpaper):
    out = subprocess.run(
        ["magick", wallpaper, "-alpha", "off", "-resize", "200x200", "-colors", "48",
         "-format", "%c", "histogram:info:-"],
        capture_output=True, text=True).stdout
    buckets, total, lum, chroma = {}, 0, 0.0, 0
    for line in out.splitlines():
        m = re.search(r"\s*(\d+):\s*\([^)]*\)\s*#([0-9A-Fa-f]{6})", line)
        if not m:
            continue
        count, hex_str = int(m.group(1)), m.group(2)
        r, g, b = (int(hex_str[i:i + 2], 16) / 255 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        total += count
        lum += count * l
        if s < 0.15 or l < 0.05 or l > 0.92:
            continue
        chroma += count
        bucket = buckets.setdefault((int(h * 360) // 30) % 12, {"wsat": 0.0, "best": None})
        bucket["wsat"] += count * s
        score = count * s * (1 if 0.12 < l < 0.55 else 0.4)
        if not bucket["best"] or score > bucket["best"][0]:
            bucket["best"] = (score, h, s)
    mean_l = lum / total if total else 0.0
    if not buckets or chroma < 0.08 * total:
        return None, 0.0, mean_l
    win = max(buckets.values(), key=lambda v: v["wsat"])
    return win["best"][1], win["best"][2], mean_l


def matugen(source_hex):
    out = subprocess.run(
        ["matugen", "color", "hex", source_hex, "-m", "dark", "-j", "hex"],
        capture_output=True, text=True, check=True,
    )
    return json.loads(out.stdout)


def tint(hue, sat, light):
    r, g, b = colorsys.hls_to_rgb(hue % 1.0, max(0.0, min(1.0, light)), max(0.0, min(1.0, sat)))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def lerp(x, x0, x1, y0, y1):
    t = max(0.0, min(1.0, (x - x0) / (x1 - x0)))
    return y0 + t * (y1 - y0)


def render_fastfetch(pill):
    """
    Recolour the fastfetch readout from the same pill palette. fastfetch has no
    daemon, so writing the rendered config is enough, the next run picks it up.
    The accent drives the keys and the torii, the surface ramp the lantern body,
    and a dim text tone the section rules, so it tracks the wallpaper like the
    pill and terminal do.
    """
    ff = Path.home() / ".config" / "fastfetch"
    tmpl = ff / "config.jsonc.in"
    if not tmpl.is_file():
        print("wallcolors: config.jsonc.in missing in ~/.config/fastfetch, skipping "
              "fastfetch recolour (apply the MasterR update or re-run the installer)",
              file=sys.stderr)
        return
    seq = lambda h: "%d;%d;%d" % tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
    repl = {
        "__LANTERN__": str(ff / "lantern.txt"),
        "__KEYS__": seq(pill["primary"]),
        "__SEP__": seq(pill["dim"]),
        "__LOGO1__": seq(pill["primary"]),
        "__LOGO2__": seq(pill["on_primary_container"]),
        "__LOGO3__": seq(pill["surface_container"]),
        "__LOGO4__": seq(pill["surface_container_high"]),
        "__LOGO5__": seq(pill["subtle"]),
        "__LOGO6__": seq(pill["outline"]),
        "__LOGO7__": seq(pill["bright"]),
    }
    out = tmpl.read_text()
    for key, val in repl.items():
        out = out.replace(key, val)
    (ff / "config.jsonc").write_text(out)


def render_kdeglobals(pill, light=False):
    """
    Recolour KDE/Qt applications (such as Dolphin) from the active rice palette.
    Writes ~/.config/kdeglobals so Dolphin and all Qt apps seamlessly inherit the
    wallpaper colors, surfaces, text tones, selection accents, and icon theme.
    """
    kdeglobals_path = Path.home() / ".config" / "kdeglobals"

    def h2rgb(hex_str):
        h = hex_str.lstrip("#")
        return "%d,%d,%d" % tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

    surf = h2rgb(pill["surface"])
    surf_low = h2rgb(pill["surface_container_low"])
    surf_mid = h2rgb(pill["surface_container"])
    surf_high = h2rgb(pill["surface_container_high"])
    surf_highest = h2rgb(pill["surface_container_highest"])

    pri = h2rgb(pill["primary"])
    pri_cont = h2rgb(pill["primary_container"])
    on_pri_cont = h2rgb(pill["on_primary_container"])
    outline = h2rgb(pill["outline"])

    cream = h2rgb(pill["cream"])
    bright = h2rgb(pill["bright"])
    subtle = h2rgb(pill["subtle"])
    dim = h2rgb(pill["dim"])

    sel_fg = surf if not light else bright

    content = f"""[Colors:Button]
BackgroundAlternate={surf_highest}
BackgroundNormal={surf_high}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={cream}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:Complementary]
BackgroundAlternate={surf_mid}
BackgroundNormal={surf}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={cream}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:Header]
BackgroundAlternate={surf_high}
BackgroundNormal={surf_mid}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={cream}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:Selection]
BackgroundAlternate={pri_cont}
BackgroundNormal={pri}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={sel_fg}
ForegroundInactive={surf_highest}
ForegroundLink={sel_fg}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={sel_fg}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:Tooltip]
BackgroundAlternate={surf_high}
BackgroundNormal={surf_highest}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={bright}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:View]
BackgroundAlternate={surf_mid}
BackgroundNormal={surf}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={cream}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[Colors:Window]
BackgroundAlternate={surf_highest}
BackgroundNormal={surf_mid}
DecorationFocus={pri}
DecorationHover={on_pri_cont}
ForegroundActive={pri}
ForegroundInactive={dim}
ForegroundLink={pri}
ForegroundNegative=210,88,70
ForegroundNeutral=189,140,58
ForegroundNormal={cream}
ForegroundPositive=91,191,115
ForegroundVisited={outline}

[General]
ColorScheme=MasterR
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark

[KFileDialog Settings]
Allow Expansion=false
Automatically select filename extension=true
Breadcrumb Navigation=true
Decoration position=2
Show Full Path=false
Show Inline Previews=true
Show Preview=false
Show Speedbar=true
Show hidden files=false
Sort by=Name
Sort directories first=true
Sort hidden files last=false
Sort reversed=false
Speedbar Width=140
View Style=DetailTree

[WM]
activeBackground={surf_mid}
activeForeground={cream}
inactiveBackground={surf}
inactiveForeground={dim}
"""
    kdeglobals_path.write_text(content)


def render_gtk(pill):
    """
    Recolour GTK3 / GTK4 applications and Qt apps running under libqgtk3.
    """
    css = f"""/* Rice matching color definitions for GTK3 / GTK4 / Libadwaita */
@define-color theme_bg_color {pill["surface_container"]};
@define-color theme_fg_color {pill["cream"]};
@define-color theme_base_color {pill["surface"]};
@define-color theme_text_color {pill["cream"]};
@define-color theme_selected_bg_color {pill["primary"]};
@define-color theme_selected_fg_color {pill["surface"]};
@define-color insensitive_bg_color {pill["surface_container_low"]};
@define-color insensitive_fg_color {pill["faint"]};
@define-color insensitive_base_color {pill["surface"]};
@define-color theme_unfocused_bg_color {pill["surface_container"]};
@define-color theme_unfocused_fg_color {pill["subtle"]};
@define-color theme_unfocused_base_color {pill["surface"]};
@define-color theme_unfocused_text_color {pill["subtle"]};
@define-color theme_unfocused_selected_bg_color {pill["primary"]};
@define-color theme_unfocused_selected_fg_color {pill["surface"]};

@define-color accent_color {pill["primary"]};
@define-color accent_bg_color {pill["primary"]};
@define-color accent_fg_color {pill["surface"]};
@define-color window_bg_color {pill["surface"]};
@define-color window_fg_color {pill["cream"]};
@define-color view_bg_color {pill["surface"]};
@define-color view_fg_color {pill["cream"]};
@define-color headerbar_bg_color {pill["surface_container"]};
@define-color headerbar_fg_color {pill["cream"]};
@define-color headerbar_border_color rgba(255, 255, 255, 0.12);
@define-color card_bg_color {pill["surface_container_high"]};
@define-color card_fg_color {pill["cream"]};
@define-color popover_bg_color {pill["surface_container"]};
@define-color popover_fg_color {pill["cream"]};
@define-color dialog_bg_color {pill["surface_container"]};
@define-color dialog_fg_color {pill["cream"]};

window, .view, .sidebar, headerbar {{
  background-color: {pill["surface"]};
  color: {pill["cream"]};
}}

.sidebar {{
  background-color: {pill["surface_container"]};
}}
"""
    for v in ["gtk-3.0", "gtk-4.0"]:
        d = Path.home() / ".config" / v
        d.mkdir(parents=True, exist_ok=True)
        (d / "gtk.css").write_text(css)


def render_satty(pill):
    """
    Recolour Satty screenshot editor to match the active rice palette.
    Updates ~/.config/satty/overrides.css and ~/.config/satty/config.toml.
    """
    satty_dir = Path.home() / ".config" / "satty"
    satty_dir.mkdir(parents=True, exist_ok=True)

    css = f"""/* Satty Theme - Styled to match MasterR liquid glass setup */
@define-color accent_color {pill["primary"]};
@define-color accent_bg_color {pill["primary"]};
@define-color accent_fg_color {pill["surface"]};
@define-color window_bg_color {pill["surface"]};
@define-color window_fg_color {pill["cream"]};
@define-color view_bg_color {pill["surface"]};
@define-color view_fg_color {pill["cream"]};
@define-color headerbar_bg_color {pill["surface_container"]};
@define-color headerbar_fg_color {pill["cream"]};
@define-color headerbar_border_color rgba(255, 255, 255, 0.12);
@define-color card_bg_color {pill["surface_container_high"]};
@define-color card_fg_color {pill["cream"]};
@define-color popover_bg_color {pill["surface_container"]};
@define-color popover_fg_color {pill["cream"]};
@define-color dialog_bg_color {pill["surface_container"]};
@define-color dialog_fg_color {pill["cream"]};

window {{
    background-color: {pill["surface"]};
    color: {pill["cream"]};
    font-family: 'Inter', sans-serif;
}}

.outer_box {{
    background-color: {pill["surface"]};
}}

.inner_box {{
    background-color: {pill["surface"]};
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 14px;
}}

.toolbar {{
    color: {pill["cream"]};
    background-color: {pill["surface_container"]};
    border: 1px solid rgba(255, 255, 255, 0.12);
    padding: 6px 12px;
    margin: 8px 12px;
    border-radius: 16px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45);
}}

.toolbar button {{
    border-radius: 10px;
    background-color: transparent;
    color: {pill["subtle"]};
    padding: 6px 10px;
    margin: 2px;
    border: 1px solid transparent;
    transition: all 150ms ease;
}}

.toolbar button:hover {{
    background-color: {pill["surface_container_highest"]};
    color: {pill["bright"]};
    border-color: rgba(255, 255, 255, 0.18);
}}

.toolbar button:checked,
.toolbar button.active,
button.editing {{
    background-color: {pill["primary"]};
    color: {pill["surface"]};
    border-color: {pill["primary"]};
    font-weight: bold;
}}

.toast {{
    color: {pill["bright"]};
    background-color: rgba(14, 29, 36, 0.94);
    border: 1px solid {pill["outline"]};
    border-radius: 12px;
    padding: 8px 16px;
    margin-top: 50px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
}}
"""
    (satty_dir / "overrides.css").write_text(css)

    pri = pill["primary"]
    cream = pill["cream"]
    surf = pill["surface"]
    pri_cont = pill["primary_container"]
    on_pri_cont = pill["on_primary_container"]

    toml = f"""[general]
fullscreen = false
resize = {{ mode = "smart" }}
floating-hack = true
auto-copy = false
early-exit = ["all"]
corner-roundness = 12
initial-tool = "brush"
copy-command = "wl-copy"
annotation-size-factor = 2
output-filename = "~/Pictures/Screenshots/Screenshot_%Y-%m-%d_%H-%M-%S_annotated.png"
save-after-copy = false
default-hide-toolbars = false
focus-toggles-toolbars = false
default-round-caps = true
primary-highlighter = "block"
no-window-decoration = false
brush-smooth-history-size = 10
title = "Satty"
app-id = "org.satty.satty"
notification-thumbnail = "screenshot"

[font]
family = "Inter"
style = "Regular"
fallback = [
    "Noto Sans CJK SC",
    "Noto Sans",
    "JetBrainsMono Nerd Font"
]

[color-palette]
palette = [
    "{pri}ff",
    "{cream}ff",
    "#ef5350ff",
    "#66bb6aff",
    "#ffa726ff",
    "#ab47bcff",
    "{surf}ff"
]
custom = [
    "{pri}",
    "{pri_cont}",
    "{on_pri_cont}",
    "{cream}",
    "#ef5350",
    "#66bb6a",
    "#ffa726",
    "#ab47bc",
    "{surf}"
]
"""
    (satty_dir / "config.toml").write_text(toml)



def main():
    if len(sys.argv) < 2:
        return 1
    if sys.argv[1] == "--hue":
        hue = (float(sys.argv[2]) % 360) / 360.0
        mode = sys.argv[3] if len(sys.argv) > 3 else "dark"
        sat = float(sys.argv[4]) if len(sys.argv) > 4 else 0.5
        sat = max(0.0, min(1.0, sat))
        mean_l = 0.85 if mode == "light" else 0.12
        chromatic = sat > 0.02
    else:
        wallpaper = sys.argv[1]
        if not Path(wallpaper).is_file():
            return 0
        hue, sat, mean_l = analyze(wallpaper)
        chromatic = hue is not None
        if not chromatic:
            hue, sat = 0.09, 0.0
    CACHE.mkdir(parents=True, exist_ok=True)

    light = mean_l >= 0.40
    surf_sat = min(sat, 0.26) if light else min(max(sat, 0.30 if chromatic else 0.0), 0.45)
    acc_sat = (min(sat + 0.18, 0.85) if light else min(max(sat, 0.30) + 0.12, 0.82)) if chromatic else 0.05
    if light:
        base = lerp(mean_l, 0.40, 0.66, 0.80, 0.93)
        steps, text, acc_l, deep_l, glow_l = LIGHT_STEPS, LIGHT_TEXT, 0.42, 0.30, 0.55
    else:
        base = lerp(mean_l, 0.0, 0.40, 0.045, 0.20)
        steps, text, acc_l, deep_l, glow_l = DARK_STEPS, DARK_TEXT, 0.70, 0.34, 0.86

    pill = {name: tint(hue, surf_sat, base + step) for name, step in zip(SURF_NAMES, steps)}
    pill["primary"] = tint(hue, acc_sat, acc_l)
    pill["primary_container"] = tint(hue, min(acc_sat + 0.08, 0.9), deep_l)
    pill["on_primary_container"] = tint(hue, min(acc_sat, 0.45), glow_l)
    pill["outline"] = tint(hue, surf_sat, base + (-0.35 if light else 0.35))
    for key, (lit, st) in zip(TEXT_KEYS, text):
        pill[key] = tint(hue, st, lit)
    (CACHE / "colors.json").write_text(json.dumps(pill, indent=2) + "\n")
    render_fastfetch(pill)
    render_kdeglobals(pill, light)
    render_gtk(pill)
    render_satty(pill)

    try:
        b = {k: v["dark"]["color"] for k, v in
             matugen(tint(hue, sat, 0.45) if chromatic else "#787878")["base16"].items()}
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        return 0

    (CACHE / "hypr-colors.lua").write_text(
        'return {\n    active = "%s",\n    inactive = "%s",\n}\n'
        % (pill["primary"], b["base01"]))

    lines = [
        f'background = {b["base00"]}',
        f'foreground = {b["base07"]}',
        f'cursor-color = {pill["primary"]}',
        f'selection-background = {b["base02"]}',
        f'selection-foreground = {b["base07"]}',
    ]
    for i in range(16):
        lines.append(f'palette = {i}={b["base%02x" % i]}')
    (CACHE / "ghostty-colors").write_text("\n".join(lines) + "\n")
    return 0




if __name__ == "__main__":
    sys.exit(main())

local home = os.getenv("HOME")
local ok, wc = pcall(dofile, home .. "/.cache/masterr/hypr-colors.lua")
if not ok then wc = nil end

local function border(hex, fallback)
    if type(hex) ~= "string" then hex = fallback end
    return "rgb(" .. hex:gsub("#", "") .. ")"
end

-- Liquid Glass Specular Bevel Border (Clean single RGBA format)
local active_glass   = "rgba(ffffff66)"
local inactive_glass = "rgba(ffffff18)"

--[[
    Splash rendering SEGVs Hyprland (pango free in renderSplash) when a monitor
    gets reconfigured while the splash would draw, e.g. a display apply from the
    pill. Logo and splash off closes that crash surface.
]]
hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
    general = {
        gaps_in          = 8,
        gaps_out         = 16,
        border_size      = 2,
        layout           = "dwindle",
        resize_on_border = true,
        ["col.active_border"]   = active_glass,
        ["col.inactive_border"] = inactive_glass,
    },
    decoration = {
        rounding         = 20,
        rounding_power   = 4,
        active_opacity   = 0.88,
        inactive_opacity = 0.48,
        shadow = {
            enabled      = true,
            range        = 32,
            render_power = 4,
            color        = 0x66000000,
        },
        blur = {
            enabled           = true,
            size              = 5,
            passes            = 2,
            vibrancy          = 0.85,
            noise             = 0.00,
            new_optimizations = true,
            xray              = false,
            special           = true,
            popups            = true,
            popups_ignorealpha = 0.2,
            ignore_opacity    = true,
        },
    },
})

-- Layer rules for Liquid Glass everywhere (MasterR Pill, Launcher, Lock, Docks, Notifications, etc.)
hl.layer_rule({ name = "pill-blur", match = { namespace = "pill.*" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "dock-blur", match = { namespace = "quickshell:.*" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "launcher-blur", match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "overview-blur", match = { namespace = "overview" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "lock-blur", match = { namespace = "lock" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "swaync-cc-blur", match = { namespace = "swaync-.*" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "notifications-blur", match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "rofi-blur", match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "osd-blur", match = { namespace = "osd" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "selection-blur", match = { namespace = "selection" }, blur = true, ignore_alpha = 0.2 })

hl.config({
    animations = {
        enabled = true,
    },
})

--[[
    Unified Spunky & Smooth Motion System:
    - spunky: Energetic spring curve with a subtle overshoot and silky settle tail, cubic-bezier(0.05, 0.90, 0.10, 1.10)
    - spunkyOvershoot: Vibrant bounce for popins and layer reveals, cubic-bezier(0.34, 1.35, 0.64, 1.00)
    - fluidSpring: Silky elastic glide for window dragging and tile snapping, cubic-bezier(0.19, 1.00, 0.22, 1.00)
    - smoothFade: Silky soft alpha and dim transitions, cubic-bezier(0.40, 0.00, 0.20, 1.00)
    - quick: Instantaneous feedback for border and cursor states, cubic-bezier(0.15, 0.00, 0.10, 1.00)
]]
hl.curve("spunky",          { type = "bezier", points = { { 0.05, 0.90 }, { 0.10, 1.10 } } })
hl.curve("spunkyOvershoot", { type = "bezier", points = { { 0.34, 1.35 }, { 0.64, 1.00 } } })
hl.curve("fluidSpring",     { type = "bezier", points = { { 0.19, 1.00 }, { 0.22, 1.00 } } })
hl.curve("smoothFade",      { type = "bezier", points = { { 0.40, 0.00 }, { 0.20, 1.00 } } })
hl.curve("quick",           { type = "bezier", points = { { 0.15, 0.00 }, { 0.10, 1.00 } } })

-- Global fallback
hl.animation({ leaf = "global",           enabled = true, speed = 4.2, bezier = "spunky" })

-- Window animations (Spunky spring popin + buttery smooth tiling repositioning)
hl.animation({ leaf = "windows",          enabled = true, speed = 4.2, bezier = "spunky" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.4, bezier = "spunkyOvershoot", style = "popin 78%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3.6, bezier = "spunky", style = "popin 82%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 4.0, bezier = "fluidSpring" })

-- Borders and angles
hl.animation({ leaf = "border",           enabled = true, speed = 3.6, bezier = "quick" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 3.4, bezier = "quick" })

-- Fading & Dimming (Silk smooth transitions)
hl.animation({ leaf = "fade",             enabled = true, speed = 3.6, bezier = "smoothFade" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 3.4, bezier = "smoothFade" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 3.2, bezier = "smoothFade" })
hl.animation({ leaf = "fadeSwitch",        enabled = true, speed = 3.6, bezier = "smoothFade" })
hl.animation({ leaf = "fadeShadow",        enabled = true, speed = 4.0, bezier = "smoothFade" })
hl.animation({ leaf = "fadeDim",           enabled = true, speed = 4.0, bezier = "smoothFade" })

-- Layer surfaces (Quickshell Pill, Launcher, Overview, OSD, Notifications)
hl.animation({ leaf = "layers",           enabled = true, speed = 4.0, bezier = "spunkyOvershoot", style = "popin 80%" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 4.0, bezier = "spunkyOvershoot", style = "popin 80%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 3.4, bezier = "spunky", style = "popin 85%" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 3.6, bezier = "smoothFade" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 3.2, bezier = "smoothFade" })

-- Workspaces & Scratchpads (Silky horizontal scroll with fluid deceleration)
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.6, bezier = "fluidSpring", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2, bezier = "spunkyOvershoot", style = "slidefadevert 25%" })

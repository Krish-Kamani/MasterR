hl.config({
    animations = {
        enabled = true,
    },
})

--[[
    Ultra-Smooth & Responsive Motion System:
    - smoothOut: Quintic/cubic fluid deceleration with instantaneous response, cubic-bezier(0.16, 1.00, 0.30, 1.00)
    - smoothSpring: Subtle, lively natural spring with refined settle, cubic-bezier(0.05, 0.95, 0.15, 1.02)
    - fluidDecel: Silky smooth glide for workspaces & window dragging, cubic-bezier(0.12, 0.98, 0.22, 1.00)
    - smoothFade: Immediate response alpha and dim transitions, cubic-bezier(0.25, 1.00, 0.50, 1.00)
    - quick: Snappy instantaneous feedback for borders, cubic-bezier(0.20, 0.00, 0.00, 1.00)
]]
hl.curve("smoothOut",       { type = "bezier", points = { { 0.16, 1.00 }, { 0.30, 1.00 } } })
hl.curve("smoothSpring",    { type = "bezier", points = { { 0.05, 0.95 }, { 0.15, 1.02 } } })
hl.curve("fluidDecel",     { type = "bezier", points = { { 0.12, 0.98 }, { 0.22, 1.00 } } })
hl.curve("smoothFade",      { type = "bezier", points = { { 0.25, 1.00 }, { 0.50, 1.00 } } })
hl.curve("quick",           { type = "bezier", points = { { 0.20, 0.00 }, { 0.00, 1.00 } } })

-- Compatibility aliases
hl.curve("spunky",          { type = "bezier", points = { { 0.05, 0.95 }, { 0.15, 1.02 } } })
hl.curve("spunkyOvershoot", { type = "bezier", points = { { 0.05, 0.95 }, { 0.15, 1.02 } } })
hl.curve("fluidSpring",     { type = "bezier", points = { { 0.12, 0.98 }, { 0.22, 1.00 } } })

-- Global fallback
hl.animation({ leaf = "global",           enabled = true, speed = 2.8, bezier = "smoothOut" })

-- Window animations (Snappy entrance + fast responsive exit + fluid dragging)
hl.animation({ leaf = "windows",          enabled = true, speed = 2.8, bezier = "smoothSpring" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 2.8, bezier = "smoothSpring", style = "popin 88%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.2, bezier = "smoothOut",    style = "popin 92%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 2.6, bezier = "fluidDecel" })

-- Borders and angles
hl.animation({ leaf = "border",           enabled = true, speed = 2.0, bezier = "quick" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 2.0, bezier = "quick" })

-- Fading & Dimming (Zero-lag silky opacity ramps)
hl.animation({ leaf = "fade",             enabled = true, speed = 2.4, bezier = "smoothFade" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2.2, bezier = "smoothFade" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2.0, bezier = "smoothFade" })
hl.animation({ leaf = "fadeSwitch",        enabled = true, speed = 2.4, bezier = "smoothFade" })
hl.animation({ leaf = "fadeShadow",        enabled = true, speed = 2.6, bezier = "smoothFade" })
hl.animation({ leaf = "fadeDim",           enabled = true, speed = 2.6, bezier = "smoothFade" })

-- Layer surfaces (Quickshell Pill, Launcher, Overview, OSD, Notifications)
hl.animation({ leaf = "layers",           enabled = true, speed = 2.8, bezier = "smoothSpring", style = "popin 88%" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 2.8, bezier = "smoothSpring", style = "popin 88%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2.0, bezier = "smoothOut",    style = "popin 92%" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2.4, bezier = "smoothFade" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 2.0, bezier = "smoothFade" })

-- Workspaces & Scratchpads (Fluid, non-stutter horizontal/vertical glide)
hl.animation({ leaf = "workspaces",       enabled = true, speed = 2.8, bezier = "fluidDecel",  style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.8, bezier = "smoothSpring", style = "slidefadevert 15%" })

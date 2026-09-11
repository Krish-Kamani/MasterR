hl.env("XCURSOR_THEME",   "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE",    "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- Automatically detect NVIDIA GPU to prevent crashes on Intel / AMD systems
local function has_nvidia()
    local f = io.open("/proc/driver/nvidia/version", "r")
    if f then f:close() return true end
    local p = io.popen("lspci 2>/dev/null | grep -i nvidia", "r")
    if p then
        local out = p:read("*a")
        p:close()
        if out and out:match("[Nn][Vv][Ii][Dd][Ii][Aa]") then return true end
    end
    return false
end

if has_nvidia() then
    hl.env("LIBVA_DRIVER_NAME",         "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__GL_GSYNC_ALLOWED",        "0")
    hl.env("__GL_VRR_ALLOWED",          "0")
end

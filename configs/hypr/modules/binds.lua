local mod = "SUPER"

-- ============================================================================
-- APPS & CORE TOOLS
-- ============================================================================
hl.bind(mod .. " + Return",         hl.dsp.exec_cmd("ghostty"))                                       -- [Apps] Terminal
hl.bind(mod .. " + E",              hl.dsp.exec_cmd("dolphin"))                                       -- [Apps] File Manager
hl.bind(mod .. " + B",              hl.dsp.exec_cmd("prime-run zen-browser"))                         -- [Apps] Zen Web Browser
hl.bind(mod .. " + SHIFT + C",       hl.dsp.exec_cmd("hyprpicker -a"))                                 -- [Apps] Color Picker

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================
hl.bind(mod .. " + W",              hl.dsp.window.close())                                            -- [Window] Close Active Window
hl.bind(mod .. " + F",              hl.dsp.window.fullscreen())                                       -- [Window] Toggle Fullscreen
hl.bind(mod .. " + T",              hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/float-toggle.sh"))    -- [Window] Toggle Floating Window
hl.bind(mod .. " + SHIFT + T",      hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/float-window.sh"))    -- [Window] Float & Pin Window
hl.bind(mod .. " + M",              hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/minimize-toggle.sh")) -- [Window] Toggle Minimize Window
hl.bind(mod .. " + mouse:272",      hl.dsp.window.drag(),   { mouse = true })                         -- [Window] Drag Window
hl.bind(mod .. " + mouse:273",      hl.dsp.window.resize(), { mouse = true })                         -- [Window] Resize Window

-- ============================================================================
-- WORKSPACES NAVIGATION & MANAGEMENT
-- ============================================================================
hl.bind(mod .. " + Left",            hl.dsp.focus({ workspace = "r-1" }))                             -- [Workspaces] Previous Workspace
hl.bind(mod .. " + Right",           hl.dsp.focus({ workspace = "r+1" }))                             -- [Workspaces] Next Workspace
hl.bind(mod .. " + mouse_up",        hl.dsp.focus({ workspace = "r-1" }))                             -- [Workspaces] Previous Workspace (Scroll Up)
hl.bind(mod .. " + mouse_down",      hl.dsp.focus({ workspace = "r+1" }))                             -- [Workspaces] Next Workspace (Scroll Down)

hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = 1 }))                                               -- [Workspaces] Switch to Workspace 1
hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = 2 }))                                               -- [Workspaces] Switch to Workspace 2
hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = 3 }))                                               -- [Workspaces] Switch to Workspace 3
hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = 4 }))                                               -- [Workspaces] Switch to Workspace 4
hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = 5 }))                                               -- [Workspaces] Switch to Workspace 5
hl.bind(mod .. " + 6", hl.dsp.focus({ workspace = 6 }))                                               -- [Workspaces] Switch to Workspace 6
hl.bind(mod .. " + 7", hl.dsp.focus({ workspace = 7 }))                                               -- [Workspaces] Switch to Workspace 7
hl.bind(mod .. " + 8", hl.dsp.focus({ workspace = 8 }))                                               -- [Workspaces] Switch to Workspace 8
hl.bind(mod .. " + 9", hl.dsp.focus({ workspace = 9 }))                                               -- [Workspaces] Switch to Workspace 9
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))                                              -- [Workspaces] Switch to Workspace 10

hl.bind(mod .. " + ALT + 1", hl.dsp.window.move({ workspace = 1,  follow = false }))                  -- [Workspaces] Move Window to Workspace 1
hl.bind(mod .. " + ALT + 2", hl.dsp.window.move({ workspace = 2,  follow = false }))                  -- [Workspaces] Move Window to Workspace 2
hl.bind(mod .. " + ALT + 3", hl.dsp.window.move({ workspace = 3,  follow = false }))                  -- [Workspaces] Move Window to Workspace 3
hl.bind(mod .. " + ALT + 4", hl.dsp.window.move({ workspace = 4,  follow = false }))                  -- [Workspaces] Move Window to Workspace 4
hl.bind(mod .. " + ALT + 5", hl.dsp.window.move({ workspace = 5,  follow = false }))                  -- [Workspaces] Move Window to Workspace 5
hl.bind(mod .. " + ALT + 6", hl.dsp.window.move({ workspace = 6,  follow = false }))                  -- [Workspaces] Move Window to Workspace 6
hl.bind(mod .. " + ALT + 7", hl.dsp.window.move({ workspace = 7,  follow = false }))                  -- [Workspaces] Move Window to Workspace 7
hl.bind(mod .. " + ALT + 8", hl.dsp.window.move({ workspace = 8,  follow = false }))                  -- [Workspaces] Move Window to Workspace 8
hl.bind(mod .. " + ALT + 9", hl.dsp.window.move({ workspace = 9,  follow = false }))                  -- [Workspaces] Move Window to Workspace 9
hl.bind(mod .. " + ALT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))                  -- [Workspaces] Move Window to Workspace 10

-- Special Workspaces (Minimized, Private, Stash, Discord)
hl.bind(mod .. " + SHIFT + M",       hl.dsp.workspace.toggle_special("minimized"))                     -- [Workspaces] Toggle Minimized Workspace
hl.bind(mod .. " + P",               hl.dsp.workspace.toggle_special("private"))                       -- [Workspaces] Toggle Private Workspace
hl.bind(mod .. " + SHIFT + P",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/special-toggle.sh private")) -- [Workspaces] Move to Private Workspace
hl.bind(mod .. " + S",               hl.dsp.workspace.toggle_special("stash"))                         -- [Workspaces] Toggle Stash Workspace
hl.bind(mod .. " + CTRL + ALT + S",  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/special-toggle.sh stash"))   -- [Workspaces] Move to Stash Workspace

-- ============================================================================
-- LAUNCHERS & OVERLAYS
-- ============================================================================
hl.bind(mod .. " + Space",           hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh launcher"))  -- [Launchers] App Launcher
hl.bind(mod .. " + ALT + Space",     hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh chatbot"))   -- [Launchers] AI Chatbot
hl.bind(mod .. " + SHIFT + E",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh finder"))    -- [Launchers] File Finder
hl.bind(mod .. " + SHIFT + F",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh finder"))    -- [Launchers] Search Files
hl.bind(mod .. " + Tab",             hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/overview-toggle.sh"))        -- [Launchers] Workspace Overview
hl.bind(mod .. " + slash",           hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh keybinds"))  -- [Launchers] System Keybinds
hl.bind(mod .. " + V",               hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh clipboard")) -- [Launchers] Clipboard History
hl.bind(mod .. " + SHIFT + W",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh wallpaper")) -- [Launchers] Wallpaper Selector
hl.bind(mod .. " + SHIFT + Return",  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh packages"))  -- [Launchers] Package Manager
hl.bind(mod .. " + G",               hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/open-surface.sh gameMode"))  -- [Launchers] Game Mode

-- ============================================================================
-- MEDIA, SCREENSHOTS & HARDWARE
-- ============================================================================
hl.bind(mod .. " + SHIFT + S",       hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh area"))        -- [Media] Screenshot Selection
hl.bind("Print",                     hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh full"))        -- [Media] Screenshot Fullscreen
hl.bind("SHIFT + Print",             hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh area"))        -- [Media] Screenshot Selection (Shift+Print)
hl.bind(mod .. " + Print",           hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/screenshot.sh window"))      -- [Media] Screenshot Active Window
hl.bind(mod .. " + ALT + S",         hl.dsp.exec_cmd("rishot"))                                                               -- [Media] RiShot Screenshot Tool
hl.bind(mod .. " + D",               hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/record.sh"))                -- [Media] Screen Recorder

hl.bind("XF86AudioRaiseVolume",      hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true }) -- [Media] Volume Up
hl.bind("XF86AudioLowerVolume",      hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true }) -- [Media] Volume Down
hl.bind("XF86AudioMute",             hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })                    -- [Media] Mute Audio
hl.bind("XF86AudioMicMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })                    -- [Media] Mute Microphone
hl.bind("XF86MonBrightnessUp",        hl.dsp.exec_cmd("brightnessctl set 5%+"),                          { locked = true, repeating = true }) -- [Media] Brightness Up
hl.bind("XF86MonBrightnessDown",      hl.dsp.exec_cmd("brightnessctl set 5%-"),                          { locked = true, repeating = true }) -- [Media] Brightness Down
hl.bind("XF86AudioPlay",             hl.dsp.global("quickshell:mediaToggle"),                           { locked = true })                    -- [Media] Play / Pause Track
hl.bind("XF86AudioNext",             hl.dsp.global("quickshell:mediaNext"),                             { locked = true })                    -- [Media] Next Track
hl.bind("XF86AudioPrev",             hl.dsp.global("quickshell:mediaPrev"),                             { locked = true })                    -- [Media] Previous Track

-- ============================================================================
-- SYSTEM & POWER
-- ============================================================================
hl.bind(mod .. " + L",               hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/lock.sh"))                   -- [System] Lock Screen
hl.bind(mod .. " + SHIFT + R",       hl.dsp.exec_cmd("hyprctl reload"))                                                       -- [System] Reload Hyprland Config

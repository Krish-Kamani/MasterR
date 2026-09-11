import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    Process {
        id: cmdProc
        command: ["true"]
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "外"
            title: "Appearance & Theming"
            subtitle: "Liquid glass profiles, Material You dynamic color extraction, hue overrides, fonts, and clock styles."
        }

        // Visual Profile
        Card {
            title: "Desktop Rendering Profile"
            subtitle: "Toggle between translucent Liquid Glass and high-contrast Solid Mode"
            icon: "sparkles"

            SegmentedBar {
                label: "Rendering Mode"
                model: [
                    { label: "✨ Liquid Glass Mode", value: "glass" },
                    { label: "⬛ Solid Mode", value: "solid" }
                ]
                currentIndex: Flags.pillBlur ? 0 : 1
                onSelected: (idx, val) => {
                    cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/liquid-glass.sh", val === "glass" ? "on" : "off"];
                    cmdProc.running = true;
                }
            }
        }

        // Color Generation & Material You
        Card {
            title: "Material You Palette Engine"
            subtitle: "Configure automatic wallpaper palette extraction or set a manual hue angle"
            icon: "palette"

            SegmentedBar {
                label: "Color Derivation Source"
                model: [
                    { label: "🖼️ Extract from Wallpaper", value: "static" },
                    { label: "🎨 Manual Custom Hue Angle", value: "manual" }
                ]
                currentIndex: Flags.paletteMode === "manual" ? 1 : 0
                onSelected: (idx, val) => {
                    Flags.paletteMode = val;
                    if (val === "manual") {
                        cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/wallcolors.py", "--hue", Flags.manualHue.toString(), Flags.manualDark ? "dark" : "light", Flags.manualSat.toString()];
                        cmdProc.running = true;
                    } else {
                        cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper.sh", "resolve"];
                        cmdProc.running = true;
                    }
                }
            }

            // Interactive Color Wheel if manual mode selected
            ColorWheel {
                visible: Flags.paletteMode === "manual"
                hue: Flags.manualHue
                saturation: Flags.manualSat
                darkMode: Flags.manualDark
                onColorChanged: (h, s, dark) => {
                    Flags.manualHue = h;
                    Flags.manualSat = s;
                    Flags.manualDark = dark;
                    cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/wallcolors.py", "--hue", h.toString(), dark ? "dark" : "light", s.toString()];
                    cmdProc.running = true;
                }
            }
        }

        // Dynamic Sync Targets
        Card {
            title: "Dynamic Synchronization Targets"
            subtitle: "Control which system components are automatically recolored when the palette changes"
            icon: "waves"

            Text {
                text: "Changes synchronize live to the following subsystems:"
                font.family: Theme.fontUI
                font.pixelSize: 12
                color: Theme.dim
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 12

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "Hyprland Specular Borders"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "Quickshell Pill & Dock"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "Ghostty GPU Terminal (DBus)"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "Fastfetch ASCII Banner & Specs"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "SDDM Login Screen (Frame Sync)"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 38
                    radius: 8
                    color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                    border.color: Theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        GlyphIcon { width: 14; height: 14; name: "check"; color: Theme.onGlow; stroke: 2.2 }
                        Text { text: "GRUB Bootloader Background"; color: Theme.bright; font.pixelSize: 11; font.family: Theme.fontUI }
                    }
                }
            }

            Button {
                text: "Sync SDDM & GRUB Wallpaper Now"
                icon: "sparkles"
                variant: "secondary"
                onClicked: {
                    cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/sync-theme-wallpaper.sh"];
                    cmdProc.running = true;
                }
            }
        }

        // Typography & Clock
        Card {
            title: "Typography, Clock & Indicators"
            subtitle: "Interface fonts, time formatting, and decorative glyphs"
            icon: "type"

            Switch {
                label: "12-Hour Clock Format"
                description: "Display AM/PM time instead of 24-hour military time in the top Pill"
                checked: Flags.time12h
                icon: "clock"
                onToggled: (st) => Flags.time12h = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Show Clock Seconds"
                description: "Render live ticking seconds in the time readout"
                checked: Flags.clockSeconds
                icon: "stopwatch"
                onToggled: (st) => Flags.clockSeconds = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Japanese Kanji Weather & Status Glyphs"
                description: "Display atmospheric kanji (晴, 曇, 雨, 雪, 霧, 雷, 月) alongside status tiles"
                checked: Flags.showGlyphs
                icon: "language"
                onToggled: (st) => Flags.showGlyphs = st
            }
        }
    }
}

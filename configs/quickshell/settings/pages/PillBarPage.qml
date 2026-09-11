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
            glyph: "丸"
            title: "Pill Top Bar"
            subtitle: "Configure the morphing desktop status pill, scale factors, gaps, and surface visibility."
        }

        // Geometry & Scale
        Card {
            title: "Pill Dimensions & Placement"
            subtitle: "Global scale and screen edge margins"
            icon: "clock"

            Slider {
                label: "Pill UI Scale Factor"
                description: "Overall scaling multiplier for fonts, icons, and faders (Default: 1.0x)"
                from: 0.8
                to: 1.4
                value: Flags.uiScale || 1.0
                stepSize: 0.05
                decimals: 2
                onMoved: (v) => Flags.uiScale = v
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Screen Top Margin Gap"
                description: "Distance from the top display bezel (0 sits flush to the screen edge)"
                from: 0
                to: 20
                value: (Flags.topGap || 1.0) * 8
                stepSize: 1
                unit: "px"
                onMoved: (v) => Flags.topGap = v / 8.0
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Window Gap Under Pill"
                description: "Buffer space between the pill and tiled application windows"
                from: 0
                to: 24
                value: (Flags.appGap || 1.0) * 12
                stepSize: 1
                unit: "px"
                onMoved: (v) => Flags.appGap = v / 12.0
            }
        }

        // Pill Translucency & Blur
        Card {
            title: "Pill Background & Opacity"
            subtitle: "Translucency and blur effect of the status pill surface"
            icon: "sparkles"

            Slider {
                label: "Pill Surface Opacity"
                description: "Background opacity (0.25 in Liquid Glass, 1.0 in Solid Mode)"
                from: 0.1
                to: 1.0
                value: Flags.pillOpacity || 1.0
                stepSize: 0.05
                decimals: 2
                onMoved: (v) => Flags.pillOpacity = v
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Enable Pill Background Blur"
                description: "Blur wallpapers and content behind the top pill bar"
                checked: Flags.pillBlur || false
                onToggled: (st) => {
                    Flags.pillBlur = st;
                    cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/liquid-glass.sh", st ? "on" : "off"];
                    cmdProc.running = true;
                }
            }
        }

        // Weather Glance Settings
        Card {
            title: "Open-Meteo Weather Glance"
            subtitle: "Configure location geocoding and forecast display"
            icon: "cloud"

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: parent.width - 150
                    spacing: 4

                    Text {
                        text: "City / Location Override"
                        font.family: Theme.fontUI
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.bright
                    }

                    Text {
                        text: "Leave empty for automatic IP geocoding, or type e.g. 'Tokyo', 'London', 'New York'"
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }

                SearchBar {
                    width: 138
                    placeholder: Flags.weatherCity || "Auto (IP)"
                    text: Flags.weatherCity || ""
                    onSearchChanged: (q) => Flags.weatherCity = q
                }
            }
        }
    }
}

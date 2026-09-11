import QtQuick
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property var monitors: []

    Process {
        id: cmdProc
        command: ["true"]
    }

    Process {
        id: getMonitorsProc
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(this.text);
                } catch (e) {}
            }
        }
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "画"
            title: "Displays & Night Light"
            subtitle: "Manage monitor resolutions, refresh rates, fractional scaling, and blue-light warmth."
        }

        // Detected Monitors Card
        Card {
            title: "Connected Displays (" + root.monitors.length + " detected)"
            subtitle: "Active Wayland outputs connected to your GPU"
            icon: "monitor"

            Column {
                width: parent.width
                spacing: 12

                Repeater {
                    model: root.monitors

                    Rectangle {
                        width: parent.width
                        height: 90
                        radius: 12
                        color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.25)
                        border.color: modelData.focused ? Theme.onGlow : Theme.border
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16

                            Rectangle {
                                width: 48
                                height: 48
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.15)
                                border.color: Theme.onGlow
                                border.width: 1

                                GlyphIcon {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    name: "monitor"
                                    color: Theme.onGlow
                                    stroke: 2.0
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Row {
                                    spacing: 8
                                    Text {
                                        text: modelData.name + (modelData.description ? (" (" + modelData.description + ")") : "")
                                        font.family: Theme.fontUI
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        color: Theme.bright
                                    }
                                    Rectangle {
                                        visible: modelData.focused
                                        width: 54
                                        height: 18
                                        radius: 4
                                        color: Theme.onGlow
                                        Text { anchors.centerIn: parent; text: "PRIMARY"; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.tileBg }
                                    }
                                }

                                Text {
                                    text: modelData.width + "x" + modelData.height + " @ " + Math.round(modelData.refreshRate) + "Hz  •  Scale: " + (modelData.scale * 100).toFixed(0) + "%  •  Position: (" + modelData.x + ", " + modelData.y + ")"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    color: Theme.dim
                                }
                            }
                        }
                    }
                }
            }

            Button {
                text: "Refresh Connected Displays"
                icon: "rotate-ccw"
                variant: "secondary"
                onClicked: getMonitorsProc.running = true
            }
        }

        // Night Light / Blue Light Filter
        Card {
            title: "Night Light (Blue Light Filter)"
            subtitle: "Warm display color temperature at night via hyprsunset to reduce eye strain"
            icon: "moon"

            SegmentedBar {
                label: "Night Light Status"
                model: [
                    { label: "❌ Off", value: "off" },
                    { label: "🌙 Always On", value: "on" },
                    { label: "⏰ Scheduled Sunset", value: "scheduled" }
                ]
                currentIndex: Flags.nightLightMode === "on" ? 1 : (Flags.nightLightMode === "scheduled" ? 2 : 0)
                onSelected: (idx, val) => {
                    Flags.nightLightMode = val;
                    if (val === "on") {
                        cmdProc.command = ["hyprctl", "hyprsunset", "temperature", Flags.nightLightTemp.toString()];
                        cmdProc.running = true;
                    } else if (val === "off") {
                        cmdProc.command = ["hyprctl", "hyprsunset", "identity"];
                        cmdProc.running = true;
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Slider {
                label: "Color Warmth Temperature"
                description: "Lower Kelvin values produce a warmer, more amber glow (Standard: 4000K)"
                from: 2200
                to: 6000
                value: Flags.nightLightTemp || 4000
                stepSize: 100
                unit: "K"
                onMoved: (v) => {
                    Flags.nightLightTemp = Math.round(v);
                    if (Flags.nightLightMode === "on") {
                        cmdProc.command = ["hyprctl", "hyprsunset", "temperature", Flags.nightLightTemp.toString()];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

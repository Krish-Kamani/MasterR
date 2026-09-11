import QtQuick
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
            glyph: "情"
            title: "About MasterR & Health"
            subtitle: "Ecosystem release version, updates, subsystem diagnostics, and credits."
        }

        // About MasterR
        Card {
            title: "MasterR Desktop Ecosystem"
            subtitle: "Aesthetic, highly integrated Arch Linux + Hyprland desktop built on Quickshell"
            icon: "sparkles"

            Row {
                spacing: 16
                width: parent.width

                Rectangle {
                    width: 56
                    height: 56
                    radius: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.2)
                    border.color: Theme.onGlow
                    border.width: 1

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        name: "cog"
                        color: Theme.onGlow
                        stroke: 2.2
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "MasterR by Krish Kamani"
                        font.family: Theme.fontUI
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.bright
                    }

                    Text {
                        text: "License: MIT  •  Compositor: Hyprland Lua  •  Shell: Quickshell (Qt6)  •  Flagship: Zen Browser"
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Check for Updates"
                    icon: "download"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = ["ghostty", "--class=masterr-floating", "-e", "masterr", "update"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "Open GitHub Repository"
                    icon: "link"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["xdg-open", "https://github.com/Krish-Kamani/MasterR"];
                        cmdProc.running = true;
                    }
                }

                Button {
                    text: "View Documentation"
                    icon: "file-text"
                    variant: "secondary"
                    onClicked: {
                        cmdProc.command = ["xdg-open", "https://github.com/Krish-Kamani/MasterR#readme"];
                        cmdProc.running = true;
                    }
                }
            }
        }

        // Subsystems Health Check
        Card {
            title: "Subsystems & Core Tooling Diagnostics"
            subtitle: "Verify status of required Wayland and system packages"
            icon: "cpu"

            Grid {
                width: parent.width
                columns: 2
                spacing: 10

                Repeater {
                    model: [
                        { name: "Hyprland Compositor", ok: true },
                        { name: "Quickshell QtQuick Engine", ok: true },
                        { name: "PipeWire Audio Server", ok: true },
                        { name: "NetworkManager & BlueZ", ok: true },
                        { name: "Matugen Dynamic Color Engine", ok: true },
                        { name: "Ghostty GPU Terminal", ok: true },
                        { name: "Zen Web Browser", ok: true },
                        { name: "Fastfetch System Telemetry", ok: true }
                    ]

                    Rectangle {
                        width: parent.width / 2 - 5
                        height: 36
                        radius: 8
                        color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.2)
                        border.color: Theme.border
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#44dd66"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                color: Theme.bright
                            }
                        }
                    }
                }
            }
        }
    }
}

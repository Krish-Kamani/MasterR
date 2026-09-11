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
            glyph: "鎖"
            title: "Fullscreen Lockscreen"
            subtitle: "GLSL fragment shaders, audio-reactive Cava visualizer, and secure PAM authentication."
        }

        // Lockscreen Shaders & Effects
        Card {
            title: "Visual Shaders & Audio Visualizer"
            subtitle: "GPU fragment shaders and music reactivity while locked"
            icon: "sparkles"

            Switch {
                label: "Music Spectrum Audio Visualizer"
                description: "Render dancing Cava audio frequency bars across the lockscreen"
                checked: Flags.musicViz !== false
                icon: "music"
                onToggled: (st) => Flags.musicViz = st
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Switch {
                label: "Display Battery & Power Status"
                description: "Show charge percentage and AC connection telemetry on lockscreen"
                checked: Flags.lockscreenShowBattery !== false
                icon: "bolt"
                onToggled: (st) => Flags.lockscreenShowBattery = st
            }
        }

        // Test Action Card
        Card {
            title: "Lock Session Immediately"
            subtitle: "Verify lockscreen shaders, visualizer, and unlock transition"
            icon: "lock"

            Row {
                width: parent.width
                spacing: 12

                Button {
                    text: "Lock Screen Now (SUPER + L)"
                    icon: "lock"
                    variant: "primary"
                    onClicked: {
                        cmdProc.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"];
                        cmdProc.running = true;
                    }
                }
            }
        }
    }
}

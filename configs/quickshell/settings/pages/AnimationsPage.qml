import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 40
    clip: true

    property string currentPreset: "spunky"
    property real animSpeed: 2.8

    Process {
        id: cmdProc
        command: ["true"]
    }

    function applyHypr(action, key, val) {
        cmdProc.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/hypr-config.py", action, key, val.toString()];
        cmdProc.running = true;
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "動"
            title: "Motion & Physics"
            subtitle: "Spring physics curves, animation presets, transition speeds, and motion tuning."
        }

        // Master Animation Toggle
        Card {
            title: "Global Motion Switch"
            subtitle: "Enable or completely disable compositor animations"
            icon: "waves"

            Switch {
                label: "Enable Animations"
                description: "Fluid window transitions, workspace panning, and surface morphing"
                checked: !Flags.reduceMotion
                icon: "waves"
                onToggled: (st) => {
                    Flags.reduceMotion = !st;
                    applyHypr("set-anim", "enabled", st ? "true" : "false");
                }
            }
        }

        // Physics Presets
        Card {
            title: "Motion Physics Curve Presets"
            subtitle: "Carefully tuned Bezier and spring profiles engineered for MasterR"
            icon: "sparkles"

            readonly property var presets: [
                { name: "spunky", label: "⚡ Spunky (Tactile Rebound)", desc: "Default MasterR curve. Very responsive with a subtle tactile snap." },
                { name: "fluidSpring", label: "🌊 Fluid Spring (Organic Glide)", desc: "Silky continuous damping with no hard stops. Ideal for smooth navigation." },
                { name: "smoothFade", label: "🎥 Smooth Fade (Cinematic)", desc: "Minimalist ease-in-out motion favored for clean presentations." },
                { name: "bouncy", label: "🎾 Bouncy (Playful Rebound)", desc: "Pronounced spring rebound physics on window spawn and resize." },
                { name: "snappy", label: "⚡ Snappy (Competitive Esport)", desc: "Near-instantaneous curve (< 100ms) for maximum reaction speed." }
            ]

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: parent.presets

                    Rectangle {
                        id: presetItem
                        width: parent.width
                        height: 54
                        radius: 10
                        property bool isSelected: root.currentPreset === modelData.name
                        color: isSelected ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.12) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, pMouse.containsMouse ? 0.35 : 0.15)
                        border.color: isSelected ? Theme.onGlow : (pMouse.containsMouse ? Theme.onGlow : Theme.border)
                        border.width: isSelected ? 1.5 : 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                anchors.verticalCenter: parent.verticalCenter
                                color: presetItem.isSelected ? Theme.onGlow : Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.2)

                                GlyphIcon {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    name: "check"
                                    color: presetItem.isSelected ? Theme.tileBg : "transparent"
                                    stroke: 2.5
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontUI
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: Theme.bright
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: Theme.fontUI
                                    font.pixelSize: 10
                                    color: Theme.dim
                                }
                            }
                        }

                        MouseArea {
                            id: pMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentPreset = modelData.name;
                                applyHypr("set-anim", "preset", modelData.name);
                            }
                        }
                    }
                }
            }
        }

        // Fine Tuning
        Card {
            title: "Physics Parameters Fine-Tuning"
            subtitle: "Adjust global animation speeds and transition paces"
            icon: "cog"

            Slider {
                label: "Animation Speed Rate"
                description: "Global animation speed multiplier (Higher = snappier transitions, Lower = cinematic slow motion)"
                from: 1.0
                to: 6.0
                value: root.animSpeed
                stepSize: 0.2
                decimals: 1
                unit: "x"
                onMoved: (v) => {
                    root.animSpeed = v;
                    applyHypr("set-anim", "speed", v.toFixed(1));
                }
            }
        }
    }
}

import QtQuick
import "../Singletons"

/**
 * Interactive 360-degree Hue Selector & Tone Palette Swatches.
 */
Column {
    id: root

    property int hue: Flags.manualHue || 30
    property real saturation: Flags.manualSat || 0.5
    property bool darkMode: Flags.manualDark

    signal colorChanged(int h, real s, bool dark)

    width: parent ? parent.width : 400
    spacing: 12

    Item {
        width: parent.width
        height: 24
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Hue Spectrum Angle"
            font.family: Theme.fontUI
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Theme.bright
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 22
            width: 50
            radius: 6
            color: Qt.hsla(root.hue / 360, root.saturation, root.darkMode ? 0.6 : 0.4, 1.0)
            border.color: Theme.border
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.hue + "°"
                font.family: Theme.fontUI
                font.pixelSize: 10
                font.weight: Font.Bold
                color: "#ffffff"
            }
        }
    }

    // Gradient Hue Track
    Rectangle {
        id: hueTrack
        width: parent.width
        height: 14
        radius: 7
        border.color: Theme.border
        border.width: 1

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#ff0000" }
            GradientStop { position: 0.17; color: "#ffff00" }
            GradientStop { position: 0.33; color: "#00ff00" }
            GradientStop { position: 0.50; color: "#00ffff" }
            GradientStop { position: 0.67; color: "#0000ff" }
            GradientStop { position: 0.83; color: "#ff00ff" }
            GradientStop { position: 1.00; color: "#ff0000" }
        }

        Rectangle {
            id: hueHandle
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(hueTrack.width - width, (root.hue / 360) * hueTrack.width - width / 2))
            color: Qt.hsla(root.hue / 360, 1.0, 0.5, 1.0)
            border.color: "#ffffff"
            border.width: 2
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor

            function updateHue(mx) {
                var ratio = Math.max(0, Math.min(1, mx / hueTrack.width));
                root.hue = Math.round(ratio * 360) % 360;
                root.colorChanged(root.hue, root.saturation, root.darkMode);
            }

            onPressed: (mouse) => updateHue(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) updateHue(mouse.x); }
        }
    }

    // Quick Swatches
    Row {
        spacing: 8
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property var swatches: [
            { name: "Flame", h: 25 },
            { name: "Amber", h: 42 },
            { name: "Emerald", h: 145 },
            { name: "Cyan", h: 185 },
            { name: "Azure", h: 215 },
            { name: "Violet", h: 270 },
            { name: "Rose", h: 330 },
            { name: "Ruby", h: 0 }
        ]

        Repeater {
            model: parent.swatches

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: Qt.hsla(modelData.h / 360, 0.8, 0.5, 1.0)
                border.color: root.hue === modelData.h ? "#ffffff" : "transparent"
                border.width: 2

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.hue = modelData.h;
                        root.colorChanged(root.hue, root.saturation, root.darkMode);
                    }
                }
            }
        }
    }
}

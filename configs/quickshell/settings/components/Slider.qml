import QtQuick
import "../Singletons"

/**
 * Modern Liquid Glass Interactive Slider with live value badge and smooth scrubbing.
 */
Item {
    id: root

    property string label: ""
    property string description: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string unit: ""
    property int decimals: 0
    property bool enabled: true

    signal moved(real val)

    width: parent ? parent.width : 400
    height: Math.max(54, headerRow.implicitHeight + 24)
    opacity: root.enabled ? 1.0 : 0.45

    Item {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(26, textCol.implicitHeight)

        Column {
            id: textCol
            anchors.left: parent.left
            anchors.right: valBadge.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.label
                font.family: Theme.fontUI
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Theme.bright
            }

            Text {
                visible: root.description.length > 0
                text: root.description
                font.family: Theme.fontUI
                font.pixelSize: 11
                color: Theme.dim
            }
        }

        // Value badge
        Rectangle {
            id: valBadge
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 22
            width: valText.implicitWidth + 16
            radius: 6
            color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.16)
            border.color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.4)
            border.width: 1

            Text {
                id: valText
                anchors.centerIn: parent
                text: (root.decimals > 0 ? root.value.toFixed(root.decimals) : Math.round(root.value)) + root.unit
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.onGlow
            }
        }
    }

    // Slider track
    Rectangle {
        id: track
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: Qt.rgba(255, 255, 255, 0.10)

        // Filled highlight
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(0, Math.min(track.width, ((root.value - root.from) / Math.max(0.001, (root.to - root.from))) * track.width))
            radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.onGlow }
                GradientStop { position: 1.0; color: Theme.vermLit }
            }
        }

        // Thumb handle
        Rectangle {
            id: thumb
            width: sliderMouse.dragActive || sliderMouse.containsMouse ? 18 : 16
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, ((root.value - root.from) / Math.max(0.001, (root.to - root.from))) * track.width - width / 2))
            color: "#ffffff"
            border.color: Theme.onGlow
            border.width: 2.5

            Behavior on width { NumberAnimation { duration: 100 } }

            Rectangle {
                anchors.centerIn: parent
                width: 4
                height: 4
                radius: 2
                color: Theme.onGlow
            }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.top: track.top
        anchors.bottom: track.bottom
        anchors.left: track.left
        anchors.right: track.right
        anchors.topMargin: -12
        anchors.bottomMargin: -12
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        property bool dragActive: false

        function updateFromMouse(mouseX) {
            var ratio = Math.max(0, Math.min(1, mouseX / track.width));
            var raw = root.from + ratio * (root.to - root.from);
            if (root.stepSize > 0) {
                raw = Math.round((raw - root.from) / root.stepSize) * root.stepSize + root.from;
            }
            root.value = Math.max(root.from, Math.min(root.to, raw));
            root.moved(root.value);
        }

        onPressed: (mouse) => {
            if (!root.enabled) return;
            dragActive = true;
            updateFromMouse(mouse.x);
        }
        onReleased: dragActive = false
        onPositionChanged: (mouse) => {
            if (pressed && root.enabled) updateFromMouse(mouse.x);
        }
    }
}

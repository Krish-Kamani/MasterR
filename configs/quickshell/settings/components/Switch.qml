import QtQuick
import "../Singletons"

/**
 * Modern fluid iOS/macOS style toggle switch row.
 * If label is omitted, acts as a compact standalone toggle knob (44x24).
 */
Item {
    id: root

    property bool checked: false
    property string label: ""
    property string description: ""
    property string icon: ""

    signal toggled(bool state)

    width: root.label.length > 0 ? (parent ? parent.width : 400) : 44
    height: root.label.length > 0 ? Math.max(42, textCol.implicitHeight + 8) : 24

    Row {
        id: leftRow
        visible: root.label.length > 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: switchTrack.left
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            visible: root.icon.length > 0
            width: 28
            height: 28
            radius: 8
            color: root.checked ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.18) : Qt.rgba(255, 255, 255, 0.05)
            border.color: root.checked ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.35) : "transparent"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            GlyphIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                name: root.icon
                color: root.checked ? Theme.onGlow : Theme.iconDim
                stroke: 2.0
            }
        }

        Column {
            id: textCol
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
    }

    // Toggle track
    Rectangle {
        id: switchTrack
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 24
        radius: 12
        color: root.checked ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.12)
        border.color: root.checked ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.18)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 160; easing.type: Easing.OutQuad }
        }

        // Thumb Knob
        Rectangle {
            id: switchThumb
            width: 18
            height: 18
            radius: 9
            y: 2
            x: root.checked ? switchTrack.width - width - 3 : 3
            color: "#ffffff"

            Behavior on x {
                NumberAnimation { duration: 160; easing.type: Easing.OutBack }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}

import QtQuick
import "../Singletons"

/**
 * Floating feedback toast for confirmation of applied changes.
 */
Rectangle {
    id: root

    property string message: ""
    property string icon: "check"

    function show(msg, ico) {
        root.message = msg;
        if (ico) root.icon = ico;
        root.opacity = 1.0;
        hideTimer.restart();
    }

    width: innerRow.implicitWidth + 24
    height: 36
    radius: 18
    color: Theme.tileBg
    border.color: Theme.onGlow
    border.width: 1
    opacity: 0.0

    Behavior on opacity { NumberAnimation { duration: 200 } }

    Timer {
        id: hideTimer
        interval: 2200
        onTriggered: root.opacity = 0.0
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 8

        GlyphIcon {
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            color: Theme.onGlow
            stroke: 2.2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.message
            font.family: Theme.fontUI
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.bright
        }
    }
}

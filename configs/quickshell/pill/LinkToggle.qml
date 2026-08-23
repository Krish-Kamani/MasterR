import QtQuick
import "Singletons"

/**
 * Toggle switch: tile bg off, terracotta fill on, cream knob slides on the
 * fast motion token. Shared by the wifi, bluetooth and hotspot controls.
 */
Rectangle {
    id: toggle

    property real s: 1
    property bool on: false
    signal toggled()

    width: 28 * s
    height: 16 * s
    radius: 999
    color: on ? Theme.verm : Theme.tileBg
    border.width: on ? 0 : 1
    border.color: Theme.border
    scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.05 : 1.0)

    Behavior on color { ColorAnimation { duration: Motion.fast } }
    Behavior on border.color { ColorAnimation { duration: Motion.fast } }
    Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 10 * toggle.s
        height: 10 * toggle.s
        radius: width / 2
        color: Theme.cream
        x: toggle.on ? toggle.width - width - 3 * toggle.s : 3 * toggle.s
        Behavior on x { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}

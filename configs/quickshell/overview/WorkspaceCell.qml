pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property int workspaceId
    required property bool isActive
    required property var windows
    required property real monWidth
    required property real monHeight
    required property real monX
    required property real monY

    signal workspaceSelected(int wsId)
    signal windowSelected(string address, int wsId)

    readonly property bool hasWindows: windows && windows.length > 0

    Rectangle {
        id: cellBg
        anchors.fill: parent
        radius: 12
        color: cellArea.containsMouse ? "#1c1c22" : "#131317"
        border.color: root.isActive ? "#dcdce8" : (cellArea.containsMouse ? "#444454" : "#24242e")
        border.width: root.isActive ? 2 : 1
        clip: true
        scale: cellArea.pressed ? 0.96 : (cellArea.containsMouse ? 1.04 : 1.0)

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        // Large subtle number when empty
        Text {
            anchors.centerIn: parent
            visible: !root.hasWindows
            text: root.workspaceId.toString()
            font.pixelSize: Math.round(parent.height * 0.40)
            font.weight: Font.DemiBold
            color: "#353540"
            opacity: 0.85
        }

        // Window items
        Repeater {
            model: root.windows

            delegate: WindowItem {
                required property var modelData
                windowData: modelData
                cellWidth: root.width
                cellHeight: root.height
                monWidth: root.monWidth
                monHeight: root.monHeight
                monX: root.monX
                monY: root.monY
                workspaceId: root.workspaceId

                onWindowClicked: (addr, wsId) => {
                    root.windowSelected(addr, wsId);
                }
            }
        }
    }

    MouseArea {
        id: cellArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1 // Behind windows
        onClicked: {
            root.workspaceSelected(root.workspaceId);
        }
    }
}

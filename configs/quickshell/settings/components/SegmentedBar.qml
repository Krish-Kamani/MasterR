import QtQuick
import "../Singletons"

/**
 * Modern segmented control / multi-option pill selector.
 */
Item {
    id: root

    property string label: ""
    property var model: []
    property int currentIndex: 0
    readonly property var currentValue: {
        if (!model || model.length === 0 || currentIndex < 0 || currentIndex >= model.length) return null;
        var item = model[currentIndex];
        return (typeof item === "object" && item.value !== undefined) ? item.value : item;
    }

    signal selected(int index, var val)

    width: parent ? parent.width : 300
    height: root.label.length > 0 ? 56 : 34

    Text {
        id: title
        visible: root.label.length > 0
        anchors.top: parent.top
        anchors.left: parent.left
        text: root.label
        font.family: Theme.fontUI
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Theme.bright
    }

    Rectangle {
        id: bar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        radius: 8
        color: Qt.rgba(255, 255, 255, 0.06)
        border.color: Qt.rgba(255, 255, 255, 0.10)
        border.width: 1

        Row {
            id: segmentsRow
            anchors.fill: parent
            anchors.margins: 2

            Repeater {
                model: root.model

                Rectangle {
                    id: segItem
                    width: segmentsRow.width / Math.max(1, root.model.length)
                    height: segmentsRow.height
                    radius: 6
                    readonly property bool isCurrent: root.currentIndex === index
                    color: isCurrent ? Theme.onGlow : (segMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: (typeof modelData === "object" && modelData.label !== undefined) ? modelData.label : modelData
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        font.weight: segItem.isCurrent ? Font.Bold : Font.Normal
                        color: segItem.isCurrent ? Theme.tileBg : (segMouse.containsMouse ? Theme.bright : Theme.subtle)
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: segMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = index;
                            var val = (typeof modelData === "object" && modelData.value !== undefined) ? modelData.value : modelData;
                            root.selected(index, val);
                        }
                    }
                }
            }
        }
    }
}

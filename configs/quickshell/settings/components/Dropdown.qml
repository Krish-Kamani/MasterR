import QtQuick
import "../Singletons"

/**
 * Modern compact dropdown selector matching MasterR styling.
 */
Item {
    id: root

    property string label: ""
    property string description: ""
    property var model: []
    property int currentIndex: 0
    readonly property var currentValue: {
        if (!model || model.length === 0 || currentIndex < 0 || currentIndex >= model.length) return null;
        var item = model[currentIndex];
        return (typeof item === "object" && item.value !== undefined) ? item.value : item;
    }
    readonly property string currentText: {
        if (!model || model.length === 0 || currentIndex < 0 || currentIndex >= model.length) return "";
        var item = model[currentIndex];
        return typeof item === "object" ? item.label : item;
    }

    signal selected(int index, var val)

    property bool opened: false

    width: parent ? parent.width : 400
    height: 44
    z: opened ? 100 : 1

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: dropBox.left
        anchors.rightMargin: 16

        Column {
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

    Rectangle {
        id: dropBox
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 170
        height: 32
        radius: 8
        color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.3)
        border.color: root.opened ? Theme.onGlow : Theme.border
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                width: parent.width - 24
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentText
                font.family: Theme.fontUI
                font.pixelSize: 12
                color: Theme.bright
                elide: Text.ElideRight
            }

            GlyphIcon {
                width: 12
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                name: root.opened ? "chevron-up" : "chevron-down"
                color: Theme.iconDim
                stroke: 2.0
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened = !root.opened
        }

        // Popup List
        Rectangle {
            visible: root.opened
            anchors.top: parent.bottom
            anchors.topMargin: 4
            anchors.right: parent.right
            width: parent.width
            implicitHeight: Math.min(200, listCol.implicitHeight + 8)
            radius: 8
            color: Theme.tileBg
            border.color: Theme.border
            border.width: 1

            Flickable {
                anchors.fill: parent
                anchors.margins: 4
                contentHeight: listCol.implicitHeight
                clip: true

                Column {
                    id: listCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: root.model

                        Rectangle {
                            width: listCol.width
                            height: 28
                            radius: 5
                            color: root.currentIndex === index ? Theme.onGlow : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: typeof modelData === "object" ? modelData.label : modelData
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                font.weight: root.currentIndex === index ? Font.Bold : Font.Normal
                                color: root.currentIndex === index ? Theme.tileBg : Theme.bright
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentIndex = index;
                                    root.opened = false;
                                    root.selected(index, root.currentValue);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

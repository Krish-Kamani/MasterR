import QtQuick
import "../Singletons"

/**
 * Modern Liquid Glass search input field with instant query updates and clear button.
 */
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search settings..."
    signal searchChanged(string query)

    height: 36
    radius: 10
    color: Qt.rgba(255, 255, 255, 0.06)
    border.color: input.activeFocus ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.12)
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 120 } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        GlyphIcon {
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            color: input.activeFocus ? Theme.onGlow : Theme.dim
            stroke: 2.0
        }

        TextInput {
            id: input
            width: parent.width - 44
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontUI
            font.pixelSize: 12
            color: Theme.bright
            clip: true
            selectByMouse: true

            Text {
                visible: input.text.length === 0
                anchors.fill: parent
                text: root.placeholder
                font.family: Theme.fontUI
                font.pixelSize: 12
                color: Theme.faint
            }

            onTextChanged: root.searchChanged(text)
        }

        MouseArea {
            visible: input.text.length > 0
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.PointingHandCursor
            onClicked: input.text = ""

            GlyphIcon {
                anchors.centerIn: parent
                width: 12
                height: 12
                name: "close"
                color: Theme.dim
                stroke: 2.0
            }
        }
    }
}

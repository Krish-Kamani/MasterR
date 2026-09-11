import QtQuick
import "../Singletons"

/**
 * Modern Inset Liquid Glass Card Container with Specular Bevel & Squircle Badge.
 */
Rectangle {
    id: root

    default property alias content: innerColumn.data
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property int spacing: 14

    width: parent ? parent.width : 600
    implicitHeight: mainCol.implicitHeight + 36
    height: implicitHeight
    radius: 16
    color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.72)
    border.color: cardMouse.containsMouse ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.35) : Qt.rgba(255, 255, 255, 0.09)
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Specular Top Highlight (Liquid Glass Bevel)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Qt.rgba(255, 255, 255, 0.22)
    }

    Column {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18
        spacing: root.spacing

        // Card Header
        Row {
            visible: root.title.length > 0
            width: parent.width
            spacing: 12

            // Icon Squircle Badge
            Rectangle {
                visible: root.icon.length > 0
                width: 34
                height: 34
                radius: 10
                color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.16)
                border.color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.35)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                GlyphIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    name: root.icon
                    color: Theme.onGlow
                    stroke: 2.0
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.title
                    font.family: Theme.fontUI
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Theme.bright
                }

                Text {
                    visible: root.subtitle.length > 0
                    text: root.subtitle
                    font.family: Theme.fontUI
                    font.pixelSize: 11
                    color: Theme.dim
                }
            }
        }

        // Inner Content Container
        Column {
            id: innerColumn
            width: parent.width
            spacing: 12
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}

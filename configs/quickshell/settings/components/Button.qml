import QtQuick
import "../Singletons"

/**
 * Modern Liquid Glass Tactile Button supporting primary, secondary, and danger styles.
 */
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string variant: "primary" // "primary", "secondary", "danger", "ghost"
    property bool enabled: true

    signal clicked()

    implicitWidth: innerRow.implicitWidth + 24
    implicitHeight: 34
    radius: 9

    scale: btnMouse.pressed ? 0.96 : (btnMouse.containsMouse ? 1.01 : 1.0)
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    readonly property color bgBase: {
        if (!root.enabled) return Qt.rgba(0.2, 0.2, 0.2, 0.3);
        if (root.variant === "primary") return btnMouse.containsMouse ? Qt.lighter(Theme.onGlow, 1.1) : Theme.onGlow;
        if (root.variant === "danger") return btnMouse.containsMouse ? "#ef4444" : "#dc2626";
        if (root.variant === "ghost") return btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent";
        // secondary frosted glass
        return btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06);
    }

    readonly property color textColor: {
        if (!root.enabled) return Theme.faint;
        if (root.variant === "primary") return Theme.tileBg;
        if (root.variant === "danger") return "#ffffff";
        return Theme.bright;
    }

    color: bgBase
    border.color: {
        if (root.variant === "secondary") return btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12);
        if (root.variant === "primary") return Qt.rgba(255, 255, 255, 0.3);
        return "transparent";
    }
    border.width: 1
    opacity: root.enabled ? 1.0 : 0.45

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // Top Specular Highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: 1
        color: Qt.rgba(255, 255, 255, 0.25)
        visible: root.variant !== "ghost" && root.enabled
    }

    Row {
        id: innerRow
        anchors.centerIn: parent
        spacing: 8

        GlyphIcon {
            visible: root.icon.length > 0
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            color: root.textColor
            stroke: 2.0
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: Theme.fontUI
            font.pixelSize: 12
            font.weight: root.variant === "primary" ? Font.Bold : Font.Medium
            color: root.textColor
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.enabled) root.clicked();
        }
    }
}

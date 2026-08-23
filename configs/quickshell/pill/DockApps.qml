pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "Singletons"

Item {
    id: root

    property real s: 1
    property var dockWindow: null
    property Item lastHoveredButton: null
    property Item draggingButton: null
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show || nameTooltipPopup.show || (draggingButton !== null)
    readonly property bool previewShowing: previewPopup.show || nameTooltipPopup.show

    implicitWidth: appRow.implicitWidth
    implicitHeight: 44 * s

    function popupCenterXForButton(button) {
        if (!button || !root.dockWindow)
            return 0;
        return root.mapToItem(root.dockWindow.contentItem, button.x + button.width / 2, 0).x;
    }

    function reorderApp(button, dir) {
        if (!button || !button.appToplevel || !button.appToplevel.appId) return;
        TaskbarApps.reorderPinnedApp(button.appToplevel.appId, dir);
    }

    Row {
        id: appRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * root.s

        Repeater {
            model: TaskbarApps.apps

            delegate: DockAppButton {
                id: btn
                required property var modelData
                s: root.s
                appToplevel: btn.modelData
                appListRoot: root
            }
        }
    }

    // 1. Live Window Preview Popup (tight card, real-time preview, app name directly above)
    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton ? root.lastHoveredButton.appToplevel : null
        property var toplevelsList: appTopLevel ? (appTopLevel.toplevels || []) : []
        property string appName: root.lastHoveredButton ? root.lastHoveredButton.appName : ""
        property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered) && toplevelsList.length > 0 && (root.draggingButton === null)
        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.dockWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.dockWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                updateTimer.restart();
            }
        }

        onShouldShowChanged: {
            updateTimer.restart();
        }

        Timer {
            id: updateTimer
            interval: 120
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }

        anchor {
            window: root.dockWindow
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: previewPopup.show && popupCard.opacity > 0.01
        color: "transparent"
        implicitWidth: root.dockWindow ? root.dockWindow.width : 600
        implicitHeight: popupCard.implicitHeight + 14 * root.s

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6 * root.s
            implicitWidth: popupCard.implicitWidth + 12 * root.s
            implicitHeight: popupCard.implicitHeight + 12 * root.s
            hoverEnabled: true
            x: Math.max(10, Math.min(parent.width - width - 10, previewPopup.cachedCenterX - width / 2))

            Rectangle {
                id: popupCard
                anchors.centerIn: parent
                radius: 10 * root.s
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0.01
                color: Theme.cardBot
                border.width: 1
                border.color: Theme.border

                implicitWidth: previewRow.implicitWidth + 14 * root.s
                implicitHeight: previewRow.implicitHeight + 14 * root.s

                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                Behavior on implicitWidth { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }
                Behavior on implicitHeight { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    shadowBlur: 0.6
                    shadowVerticalOffset: 4 * root.s
                }

                // Inner top sheen line
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: parent.radius * 0.6
                    anchors.rightMargin: parent.radius * 0.6
                    height: 1
                    color: Theme.sheen
                }

                Row {
                    id: previewRow
                    anchors.centerIn: parent
                    spacing: 8 * root.s

                    Repeater {
                        model: previewPopup.toplevelsList

                        delegate: Item {
                            id: windowItem
                            required property var modelData
                            implicitWidth: previewCol.implicitWidth
                            implicitHeight: previewCol.implicitHeight

                            Column {
                                id: previewCol
                                anchors.centerIn: parent
                                spacing: 5 * root.s

                                // App Name directly above the preview + close button
                                RowLayout {
                                    width: Math.max(160 * root.s, screencopyView.implicitWidth)
                                    spacing: 4 * root.s

                                    Text {
                                        Layout.fillWidth: true
                                        text: previewPopup.appName || (windowItem.modelData && windowItem.modelData.title ? windowItem.modelData.title : "App")
                                        color: Theme.cream
                                        font.family: Theme.font
                                        font.pixelSize: 11 * root.s
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    // Compact close button (x)
                                    Rectangle {
                                        id: closeBtn
                                        width: 16 * root.s
                                        height: 16 * root.s
                                        radius: 8 * root.s
                                        color: closeArea.containsMouse ? Theme.vermBurn : "transparent"
                                        border.width: 1
                                        border.color: closeArea.containsMouse ? Theme.vermLit : "transparent"

                                        GlyphIcon {
                                            anchors.centerIn: parent
                                            width: 9 * root.s
                                            height: 9 * root.s
                                            name: "close"
                                            color: closeArea.containsMouse ? Theme.bright : Theme.subtle
                                            stroke: 2.0
                                        }

                                        MouseArea {
                                            id: closeArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (windowItem.modelData && typeof windowItem.modelData.close === "function") {
                                                    windowItem.modelData.close();
                                                }
                                            }
                                        }
                                    }
                                }

                                // Live real-time window thumbnail with zero unnecessary blank space
                                Rectangle {
                                    id: thumbBox
                                    width: Math.max(160 * root.s, screencopyView.implicitWidth)
                                    height: screencopyView.implicitHeight
                                    radius: 6 * root.s
                                    color: "transparent"
                                    border.width: 1
                                    border.color: winMouseArea.containsMouse ? Theme.frameBorder : Theme.hair
                                    clip: true

                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowItem.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(240 * root.s, 145 * root.s)
                                    }

                                    MouseArea {
                                        id: winMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.LeftButton) {
                                                if (windowItem.modelData && typeof windowItem.modelData.activate === "function") {
                                                    windowItem.modelData.activate();
                                                    previewPopup.show = false;
                                                }
                                            } else if (mouse.button === Qt.MiddleButton) {
                                                if (windowItem.modelData && typeof windowItem.modelData.close === "function") {
                                                    windowItem.modelData.close();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 2. Clean App Name Tooltip Popup (shown when hovering on app without open windows)
    PopupWindow {
        id: nameTooltipPopup
        property var appTopLevel: root.lastHoveredButton ? root.lastHoveredButton.appToplevel : null
        property var toplevelsList: appTopLevel ? (appTopLevel.toplevels || []) : []
        property string appName: root.lastHoveredButton ? root.lastHoveredButton.appName : ""
        property bool shouldShow: root.buttonHovered && toplevelsList.length === 0 && appName.length > 0 && (root.draggingButton === null)
        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.dockWindow)
                    nameTooltipPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.dockWindow)
                    nameTooltipPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                nameTimer.restart();
            }
        }

        onShouldShowChanged: nameTimer.restart()

        Timer {
            id: nameTimer
            interval: 80
            onTriggered: nameTooltipPopup.show = nameTooltipPopup.shouldShow
        }

        anchor {
            window: root.dockWindow
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: nameTooltipPopup.show && nameBubble.opacity > 0.01
        color: "transparent"
        implicitWidth: root.dockWindow ? root.dockWindow.width : 600
        implicitHeight: 50 * root.s

        Rectangle {
            id: nameBubble
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6 * root.s
            x: Math.max(10, Math.min(parent.width - width - 10, nameTooltipPopup.cachedCenterX - width / 2))
            width: nameText.implicitWidth + 24 * root.s
            height: nameText.implicitHeight + 14 * root.s
            implicitWidth: width
            implicitHeight: height
            radius: 8 * root.s
            opacity: nameTooltipPopup.show ? 1 : 0
            visible: opacity > 0.01
            color: Theme.cardBot
            border.width: 1
            border.color: Theme.border

            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: 0.6
                shadowVerticalOffset: 3 * root.s
            }

            Text {
                id: nameText
                anchors.centerIn: parent
                text: nameTooltipPopup.appName
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.weight: Font.Bold
            }
        }
    }
}

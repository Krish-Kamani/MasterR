pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "Singletons"

PanelWindow {
    id: dockRoot

    property var screenData: null
    screen: screenData

    readonly property real s: screenData ? (screenData.height / 1080) * Flags.uiScale : 1
    readonly property real bottomGap: Math.round((Flags.dockBottomGap !== undefined ? Flags.dockBottomGap : 8) * s)
    readonly property real windowGap: Math.round((Flags.dockWindowGap !== undefined ? Flags.dockWindowGap : 8) * s)
    readonly property real hoverRegionHeight: Math.max(16 * s, 14)
    readonly property real dockH: Math.round((Flags.dockHeight || 52) * s)

    signal requestLauncher()

    visible: Flags.dockEnable && !monFullscreen

    readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(screenData)
    readonly property HyprlandWorkspace activeWs: hyprMonitor ? hyprMonitor.activeWorkspace : null

    readonly property bool monFullscreen: {
        if (!activeWs) return false;
        var o = activeWs.lastIpcObject;
        return o ? !!o.hasfullscreen : false;
    }

    readonly property int activeWorkspaceWindowCount: {
        if (!screenData) return 0;
        var actName = "";
        var mons = Hyprland.monitors.values;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === screenData.name && mons[i].activeWorkspace) {
                actName = mons[i].activeWorkspace.name;
                break;
            }
        }
        if (!actName) return 0;

        var tls = Hyprland.toplevels.values;
        var count = 0;
        for (var j = 0; j < tls.length; j++) {
            var t = tls[j];
            if (t && t.workspace && t.workspace.name === actName) {
                count++;
            }
        }
        return count;
    }

    readonly property bool isDesktopClear: activeWorkspaceWindowCount === 0

    readonly property bool shouldPin: Flags.dockPinned && Flags.dockPinMode === "always"

    readonly property bool isHovered: (Flags.dockHoverToReveal && (dockPillHoverArea.containsMouse || pillHover.hovered)) || dockApps.requestDockShow

    readonly property bool reveal: shouldPin || (Flags.dockPinMode === "desktop" && isDesktopClear) || isHovered

    anchors {
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Exact height matching the dock pill and bottom gap so top edge sits directly at the top of the pill
    implicitHeight: Math.round(dockH + bottomGap)
    exclusiveZone: shouldPin ? Math.max(0, Math.round(dockH + bottomGap - 16 * s - 12 * (1 - Flags.appGap) * s)) : 0

    mask: Region {
        item: dockPillHoverArea
    }

    // Centered Dock Pill Area (strictly constrained to dock width, triggers only within dock zone)
    MouseArea {
        id: dockPillHoverArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: Math.max(dockBackground.width + 36 * dockRoot.s, 400 * dockRoot.s)
        height: dockRoot.reveal ? dockRoot.implicitHeight : dockRoot.hoverRegionHeight
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        Behavior on height {
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Motion.fast
                easing.type: Motion.easeStandard
            }
        }

        HoverHandler {
            id: pillHover
        }

        Item {
            id: dockVisualContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dockRoot.reveal ? dockRoot.bottomGap : (-dockRoot.dockH - dockRoot.bottomGap - 16 * dockRoot.s)
            width: dockBackground.width
            height: dockBackground.height

                opacity: dockRoot.reveal ? 1.0 : 0.0
                visible: opacity > 0.005

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: Motion.morph
                        easing.type: Motion.easeMorph
                        easing.bezierCurve: Motion.morphCurve
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.standard
                        easing.type: Motion.easeStandard
                    }
                }

                Rectangle {
                    id: dockBackground
                    anchors.centerIn: parent
                    width: dockContentRow.implicitWidth + 24 * dockRoot.s
                    height: dockRoot.dockH
                    radius: 16 * dockRoot.s
                    border.width: 1
                    border.color: Theme.border

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(Theme.cardTop, Flags.pillOpacity) }
                        GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBot, Flags.pillOpacity) }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
                        shadowBlur: 0.7
                        shadowVerticalOffset: 3 * dockRoot.s
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
                        id: dockContentRow
                        anchors.centerIn: parent
                        spacing: 6 * dockRoot.s

                        // 1. Pin Toggle Button (Cycles: desktop -> always -> autohide)
                        Rectangle {
                            id: pinBtn
                            width: 36 * dockRoot.s
                            height: 36 * dockRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 8 * dockRoot.s
                            readonly property bool isPinActive: Flags.dockPinMode === "always" || Flags.dockPinMode === "desktop"
                            color: isPinActive
                                ? Qt.alpha(Theme.onGlow, 0.16)
                                : (pinArea.containsMouse ? Theme.frameBg : "transparent")
                            border.width: 1
                            border.color: isPinActive ? Qt.alpha(Theme.onGlow, 0.3) : (pinArea.containsMouse ? Theme.frameBorder : "transparent")

                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 18 * dockRoot.s
                                height: 18 * dockRoot.s
                                name: Flags.dockPinMode === "always" ? "keep" : "pin"
                                color: pinBtn.isPinActive ? Theme.onGlow : (pinArea.containsMouse ? Theme.cream : Theme.iconDim)
                                stroke: 1.9
                            }

                            MouseArea {
                                id: pinArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    if (Flags.dockPinMode === "desktop") {
                                        Flags.dockPinMode = "always";
                                    } else if (Flags.dockPinMode === "always") {
                                        Flags.dockPinMode = "autohide";
                                    } else {
                                        Flags.dockPinMode = "desktop";
                                    }
                                }
                            }

                            Tooltip {
                                s: dockRoot.s
                                placement: "above"
                                title: Flags.dockPinMode === "always"
                                    ? "Fully Pinned"
                                    : (Flags.dockPinMode === "desktop" ? "Smart Pin (Desktop)" : "Auto-Hide")
                                desc: ""
                                show: pinArea.containsMouse
                            }
                        }

                        DockSeparator {
                            s: dockRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // 2. Taskbar Apps
                        DockApps {
                            id: dockApps
                            s: dockRoot.s
                            dockWindow: dockRoot
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DockSeparator {
                            s: dockRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // 3. App Launcher Button
                        Rectangle {
                            id: launcherBtn
                            width: 36 * dockRoot.s
                            height: 36 * dockRoot.s
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 8 * dockRoot.s
                            color: launcherArea.containsMouse ? Theme.frameBg : "transparent"
                            border.width: 1
                            border.color: launcherArea.containsMouse ? Theme.frameBorder : "transparent"

                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 18 * dockRoot.s
                                height: 18 * dockRoot.s
                                name: "apps"
                                color: launcherArea.containsMouse ? Theme.cream : Theme.iconDim
                                stroke: 1.8
                            }

                            MouseArea {
                                id: launcherArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    dockRoot.requestLauncher();
                                }
                            }

                            Tooltip {
                                s: dockRoot.s
                                placement: "above"
                                title: "Applications"
                                desc: ""
                                show: launcherArea.containsMouse
                            }
                    }
                }
            }
        }
    }
}

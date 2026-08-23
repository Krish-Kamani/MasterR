//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    property bool shown: false
    property string targetMonitor: ""

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    Component.onCompleted: {
        root.refresh();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.refresh();
        }
    }

    IpcHandler {
        target: "overview"
        function show(mon: string): void {
            if (!mon || mon.length === 0)
                mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
            root.targetMonitor = mon;
            root.refresh();
            root.shown = true;
        }
        function hide(): void {
            root.shown = false;
        }
        function toggle(mon: string): void {
            if (root.shown) {
                root.shown = false;
                return;
            }
            if (!mon || mon.length === 0)
                mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
            root.targetMonitor = mon;
            root.refresh();
            root.shown = true;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            screen: modelData
            visible: root.shown && (root.targetMonitor.length === 0 || root.targetMonitor === modelData.name)

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "overview"

            anchors { top: true; left: true; right: true; bottom: true }

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.5
            }

            // Click outside dismisses overview
            MouseArea {
                anchors.fill: parent
                onClicked: root.shown = false
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: win.visible

                Keys.onEscapePressed: {
                    root.shown = false;
                }

                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Escape) {
                        root.shown = false;
                        e.accepted = true;
                    } else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                        var targetWs = e.key - Qt.Key_0;
                        Hyprland.dispatch("workspace " + targetWs);
                        root.shown = false;
                        e.accepted = true;
                    } else if (e.key === Qt.Key_0) {
                        Hyprland.dispatch("workspace 10");
                        root.shown = false;
                        e.accepted = true;
                    }
                }

                Overview {
                    id: overview
                    anchors.centerIn: parent
                    screenData: win.modelData

                    onCloseRequested: root.shown = false
                }
            }

            onVisibleChanged: {
                if (win.visible) {
                    root.refresh();
                    focusScope.forceActiveFocus();
                }
            }
        }
    }
}

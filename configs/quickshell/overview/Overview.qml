pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property var screenData
    signal closeRequested()

    readonly property real s: screenData ? (screenData.height / 1080) : 1
    readonly property real monW: screenData ? screenData.width : 1920
    readonly property real monH: screenData ? screenData.height : 1080
    readonly property real monX: screenData ? (screenData.x || 0) : 0
    readonly property real monY: screenData ? (screenData.y || 0) : 0

    readonly property real cellWidth: Math.round(284 * s)
    readonly property real cellHeight: Math.round(cellWidth * (monH / monW))
    readonly property real gridGap: Math.round(10 * s)
    readonly property real panelPadding: Math.round(16 * s)

    implicitWidth: gridLayout.implicitWidth + panelPadding * 2
    implicitHeight: gridLayout.implicitHeight + panelPadding * 2

    readonly property string currentScreenName: screenData ? screenData.name : ""

    readonly property int activeWsId: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i].name === root.currentScreenName && ms[i].activeWorkspace) {
                return ms[i].activeWorkspace.id;
            }
        }
        return (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace) ? Hyprland.focusedMonitor.activeWorkspace.id : 1;
    }

    readonly property var toplevelsList: (typeof Hyprland !== "undefined" && Hyprland.toplevels) ? Hyprland.toplevels.values : []

    function getWindowsForWorkspace(wsId) {
        void root.toplevelsList;
        var out = [];
        for (var i = 0; i < root.toplevelsList.length; i++) {
            var t = root.toplevelsList[i];
            if (!t) continue;
            var wId = -1;
            if (t.workspace && typeof t.workspace.id === "number") {
                wId = t.workspace.id;
            } else if (t.lastIpcObject && t.lastIpcObject.workspace) {
                wId = t.lastIpcObject.workspace.id;
            }
            if (wId === wsId) {
                out.push(t);
            }
        }
        return out;
    }

    function selectWorkspace(wsId) {
        Hyprland.dispatch("workspace " + wsId);
        root.closeRequested();
    }

    function selectWindow(address, wsId) {
        var addr = address;
        if (addr && addr.length > 0) {
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            Hyprland.dispatch("focuswindow address:" + addr);
        }
        Hyprland.dispatch("workspace " + wsId);
        root.closeRequested();
    }

    // Outer Container matching end-4 / masterr panel styling
    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: Math.round(18 * root.s)
        color: "#0f0f13"
        border.color: "#282832"
        border.width: 1
        opacity: 0.97

        // Subtle inner highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.round(17 * root.s)
            color: "transparent"
            border.color: "#ffffff"
            border.width: 1
            opacity: 0.06
        }
    }

    // 2x5 Grid of Workspaces
    Grid {
        id: gridLayout
        anchors.centerIn: parent
        columns: 5
        rows: 2
        spacing: root.gridGap

        Repeater {
            model: 10 // Workspaces 1 to 10

            delegate: WorkspaceCell {
                required property int index
                readonly property int wsId: index + 1

                width: root.cellWidth
                height: root.cellHeight

                workspaceId: wsId
                isActive: root.activeWsId === wsId
                windows: root.getWindowsForWorkspace(wsId)
                monWidth: root.monW
                monHeight: root.monH
                monX: root.monX
                monY: root.monY

                onWorkspaceSelected: (targetWsId) => root.selectWorkspace(targetWsId)
                onWindowSelected: (addr, targetWsId) => root.selectWindow(addr, targetWsId)
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "Singletons"

/**
 * OverviewSurface: A 10-workspace visual overview grid (2 rows x 5 columns)
 * matching the MasterR / Washi theme.
 *
 * Features:
 * - Real-time live window previews with ScreencopyView.
 * - Arrow key navigation across the 2x5 grid with live background workspace switching.
 * - Mouse drag-and-drop: drag any window across workspaces to move it.
 * - Return/Enter confirmation and small Roman numeral indicators (I - X).
 */
PillSurface {
    id: root

    property string screenName: ""

    mTop: 14
    mLeft: 16
    mRight: 16
    mBottom: 14

    ameForm: "off"

    // Drag and Drop State
    property bool isDragging: false
    property string dragAddress: ""
    property string dragTitle: ""
    property string dragClass: ""
    property string dragIconSrc: ""
    property int dragFromWs: -1
    property real dragX: 0
    property real dragY: 0
    property real dragW: 0
    property real dragH: 0
    property int dropTargetWs: -1

    function getWorkspaceAt(rx, ry) {
        for (var i = 0; i < gridRepeater.count; i++) {
            var cell = gridRepeater.itemAt(i);
            if (!cell) continue;
            var p = cell.mapFromItem(root, rx, ry);
            if (p.x >= 0 && p.x <= cell.width && p.y >= 0 && p.y <= cell.height) {
                return cell.wsId;
            }
        }
        return -1;
    }

    function moveWindowToWorkspace(address, targetWs) {
        var addr = address;
        if (addr && addr.length > 0) {
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            Hyprland.dispatch('hl.dsp.window.move({ workspace = ' + targetWs + ', follow = false, window = "address:' + addr + '" })');
        }
    }

    function toRoman(num) {
        var romans = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
        return (num >= 1 && num <= 10) ? romans[num - 1] : String(num);
    }

    readonly property real monW: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === root.screenName && ms[i].width > 0)
                return ms[i].width;
        }
        return 1920;
    }

    readonly property real monH: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === root.screenName && ms[i].height > 0)
                return ms[i].height;
        }
        return 1080;
    }

    readonly property real monX: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === root.screenName)
                return ms[i].x || 0;
        }
        return 0;
    }

    readonly property real monY: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === root.screenName)
                return ms[i].y || 0;
        }
        return 0;
    }

    readonly property int activeWsId: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === root.screenName && ms[i].activeWorkspace) {
                return ms[i].activeWorkspace.id;
            }
        }
        return (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace) ? Hyprland.focusedMonitor.activeWorkspace.id : 1;
    }

    property int focusedWsId: activeWsId

    property string lockedWindowAddr: ""
    property int windowCurrentWs: -1

    property int selectedWinIndex: 0
    property string selectedWinAddress: ""

    function resetLockedWindow() {
        lockedWindowAddr = "";
        windowCurrentWs = -1;
        selectedWinIndex = 0;
        selectedWinAddress = "";
    }

    onOpenChanged: {
        if (open) {
            focusedWsId = activeWsId;
            resetLockedWindow();
        } else {
            isDragging = false;
            dragAddress = "";
            dropTargetWs = -1;
            resetLockedWindow();
        }
    }

    function selectWindowKey(key) {
        var wins = root.getWindowsForWorkspace(focusedWsId);
        if (!wins || wins.length === 0) return;

        var k = (key || "").toLowerCase();
        if (k === "d" || k === "s") {
            selectedWinIndex = (selectedWinIndex + 1) % wins.length;
        } else if (k === "a" || k === "w") {
            selectedWinIndex = (selectedWinIndex - 1 + wins.length) % wins.length;
        }

        var w = wins[selectedWinIndex];
        if (w) {
            var ipc = w.lastIpcObject || w;
            var addr = w.address || (ipc ? ipc.address : "");
            selectedWinAddress = addr;
            lockedWindowAddr = addr;
            windowCurrentWs = focusedWsId;
        }
    }

    function moveFocus(dir) {
        var idx = Math.max(0, Math.min(9, focusedWsId - 1));

        if (dir === "right" || dir === 1) {
            idx = (idx + 1) % 10;
        } else if (dir === "left" || dir === -1) {
            idx = (idx - 1 + 10) % 10;
        } else if (dir === "up") {
            if (idx >= 5) idx -= 5;
            else idx += 5;
        } else if (dir === "down") {
            if (idx < 5) idx += 5;
            else idx -= 5;
        }

        var targetWs = idx + 1;
        focusedWsId = targetWs;
        resetLockedWindow();

        // Switch workspace in the background live as you move
        Hyprland.dispatch('hl.dsp.focus({workspace="' + targetWs + '"})');
    }

    function getActiveOrFirstWindowForWorkspace(wsId) {
        var wins = root.getWindowsForWorkspace(wsId);
        if (!wins || wins.length === 0) return null;

        if (root.selectedWinAddress.length > 0) {
            for (var i = 0; i < wins.length; i++) {
                var w = wins[i];
                var ipc = w.lastIpcObject || w;
                var addr = w.address || (ipc ? ipc.address : "");
                if (addr === root.selectedWinAddress) return w;
            }
        }
        if (root.selectedWinIndex >= 0 && root.selectedWinIndex < wins.length) {
            return wins[root.selectedWinIndex];
        }
        return wins[0];
    }

    function moveActiveWindow(dir) {
        var addr = root.lockedWindowAddr;
        var currWs = root.windowCurrentWs;

        // If not already locked to a window, find the active window on focusedWsId
        if (!addr || addr.length === 0 || currWs < 1) {
            var win = root.getActiveOrFirstWindowForWorkspace(focusedWsId);
            if (!win) return;

            var ipc = win.lastIpcObject || win;
            addr = win.address || (ipc ? ipc.address : "");
            if (!addr || addr.length === 0) return;

            currWs = focusedWsId;
            root.lockedWindowAddr = addr;
            root.windowCurrentWs = currWs;
        }

        var idx = Math.max(0, Math.min(9, currWs - 1));

        if (dir === "right" || dir === 1) {
            idx = (idx + 1) % 10;
        } else if (dir === "left" || dir === -1) {
            idx = (idx - 1 + 10) % 10;
        } else if (dir === "up") {
            if (idx >= 5) idx -= 5;
            else idx += 5;
        } else if (dir === "down") {
            if (idx < 5) idx += 5;
            else idx -= 5;
        }

        var targetWs = idx + 1;
        if (targetWs === currWs) return;

        // Move window to target workspace with follow = false so focus stays where it was
        root.moveWindowToWorkspace(addr, targetWs);

        // Update the tracked current workspace of the window for continuous subsequent arrow presses
        root.windowCurrentWs = targetWs;
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
        focusedWsId = wsId;
        Hyprland.dispatch('hl.dsp.focus({workspace="' + wsId + '"})');
        root.requestClose();
    }

    function selectWindow(address, wsId) {
        focusedWsId = wsId;
        var addr = address;
        if (addr && addr.length > 0) {
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            Hyprland.dispatch('hl.dsp.focuswindow("address:' + addr + '")');
        }
        Hyprland.dispatch('hl.dsp.focus({workspace="' + wsId + '"})');
        root.requestClose();
    }

    function resolveIcon(winClass, winTitle) {
        var rawClass = (winClass || "").trim();
        var lower = rawClass.toLowerCase();

        var aliases = {
            "com.mitchellh.ghostty": "ghostty",
            "ghostty": "ghostty",
            "kitty": "kitty",
            "org.kde.dolphin": "org.kde.dolphin",
            "dolphin": "org.kde.dolphin",
            "org.gnome.nautilus": "org.gnome.nautilus",
            "nautilus": "org.gnome.nautilus",
            "zen": "zen",
            "zen-browser": "zen",
            "app.zen_browser.zen": "zen",
            "firefox": "firefox",
            "org.mozilla.firefox": "firefox",
            "google-chrome-stable": "google-chrome",
            "google-chrome": "google-chrome",
            "chromium": "chromium",
            "chromium-browser": "chromium",
            "code": "code",
            "code-oss": "code",
            "visual-studio-code": "code",
            "spotify": "spotify",
            "discord": "discord",
            "vesktop": "vesktop",
            "antigravity": "/opt/antigravity/antigravity.png",
            "google-antigravity": "/opt/antigravity/antigravity.png",
            "satty": "satty",
            "mpv": "mpv",
            "obsidian": "obsidian",
            "telegramdesktop": "telegram",
            "org.telegram.desktop": "telegram"
        };

        if (aliases[lower]) {
            var aliasVal = aliases[lower];
            if (aliasVal.indexOf("/") === 0 || aliasVal.indexOf("file://") === 0) return aliasVal;
            var ap = Quickshell.iconPath(aliasVal, "");
            if (ap && ap.length > 0) return ap;
        }

        var e = DesktopEntries.heuristicLookup(lower);
        if (e && e.icon) {
            var eIcon = e.icon;
            if (eIcon.indexOf("/") === 0 || eIcon.indexOf("file://") === 0) return eIcon;
            var ep = Quickshell.iconPath(eIcon, "");
            if (ep && ep.length > 0) return ep;
        }

        var apps = DesktopEntries.applications.values;
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            if (!a) continue;
            var aid = (a.id || "").toLowerCase().replace(/\.desktop$/, "");
            if (aid === lower && a.icon) {
                var aip = Quickshell.iconPath(a.icon, "");
                if (aip && aip.length > 0) return aip;
            }
        }

        var clean = lower.replace(/\.desktop$/, "").replace(/^org\.(kde|gnome|mozilla)\./, "");
        var pClean = Quickshell.iconPath(clean, "");
        if (pClean && pClean.length > 0) return pClean;

        var pDirect = Quickshell.iconPath(lower, "");
        if (pDirect && pDirect.length > 0) return pDirect;

        return Quickshell.iconPath("application-x-executable", "");
    }

    readonly property real cellWidth: Math.round(198 * root.s)
    readonly property real cellHeight: Math.round(cellWidth * (root.monH / root.monW))
    readonly property real gap: Math.round(8 * root.s)

    implicitWidth: grid.implicitWidth + (mLeft + mRight) * root.s
    implicitHeight: grid.implicitHeight + (mTop + mBottom) * root.s

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: 5
        rows: 2
        spacing: root.gap

        Repeater {
            id: gridRepeater
            model: 10 // Workspaces 1 to 10

            delegate: Item {
                id: wsCell
                required property int index
                readonly property int wsId: index + 1

                width: root.cellWidth
                height: root.cellHeight

                readonly property bool isSelected: root.focusedWsId === wsId
                readonly property bool isActive: root.activeWsId === wsId
                readonly property bool isDropTarget: root.isDragging && root.dropTargetWs === wsId
                readonly property var wsWindows: root.getWindowsForWorkspace(wsId)
                readonly property bool hasWindows: wsWindows && wsWindows.length > 0

                Rectangle {
                    id: wsCellBg
                    anchors.fill: parent
                    radius: Math.round(8 * root.s)
                    color: wsCell.isDropTarget ? Theme.ghost : (wsCell.isSelected ? Theme.cardTop : (wsArea.containsMouse ? Theme.cardTop : Theme.tileBg))
                    border.color: wsCell.isDropTarget ? Theme.vermLit : (wsCell.isSelected ? Theme.vermLit : (wsCell.isActive ? Theme.cream : (wsArea.containsMouse ? Theme.hair : Theme.border)))
                    border.width: (wsCell.isDropTarget || wsCell.isSelected || wsCell.isActive) ? 2 : 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                    // Small subtle Roman numeral when workspace is empty
                    Text {
                        anchors.centerIn: parent
                        visible: !wsCell.hasWindows
                        text: root.toRoman(wsCell.wsId)
                        font.family: Theme.font
                        font.pixelSize: Math.round(12 * root.s)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5 * root.s
                        color: (wsCell.isDropTarget || wsCell.isSelected) ? Theme.vermLit : (wsCell.isActive ? Theme.cream : (wsArea.containsMouse ? Theme.cream : Theme.dim))
                        opacity: (wsCell.isDropTarget || wsCell.isSelected || wsCell.isActive) ? 1.0 : (wsArea.containsMouse ? 0.9 : 0.55)

                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                    }

                    // Render windows inside workspace
                    Repeater {
                        model: wsCell.wsWindows

                        delegate: Item {
                            id: winItem
                            required property int index
                            required property var modelData

                            readonly property var ipc: winItem.modelData ? (winItem.modelData.lastIpcObject || winItem.modelData) : null
                            readonly property var waylandTl: (winItem.modelData && winItem.modelData.wayland) ? winItem.modelData.wayland : null
                            readonly property string address: (winItem.modelData && winItem.modelData.address) ? winItem.modelData.address : (ipc ? ipc.address : "")
                            readonly property string title: (winItem.modelData && winItem.modelData.title) ? winItem.modelData.title : (ipc ? ipc.title : "")
                            readonly property string winClass: (ipc && ipc.class) ? ipc.class : ((winItem.modelData && winItem.modelData.wayland && winItem.modelData.wayland.appId) ? winItem.modelData.wayland.appId : "")
                            readonly property bool isFullscreen: ipc ? (ipc.fullscreen === 1 || ipc.fullscreen === 2) : false

                            readonly property bool isSelectedWin: {
                                if (root.lockedWindowAddr.length > 0) {
                                    return root.lockedWindowAddr === winItem.address;
                                }
                                if (wsCell.isSelected && root.selectedWinAddress.length > 0) {
                                    return root.selectedWinAddress === winItem.address;
                                }
                                return wsCell.isSelected && wsCell.hasWindows && winItem.index === root.selectedWinIndex;
                            }

                            readonly property real winX: (ipc && ipc.at && ipc.at.length >= 2) ? ipc.at[0] : 0
                            readonly property real winY: (ipc && ipc.at && ipc.at.length >= 2) ? ipc.at[1] : 0
                            readonly property real winW: (ipc && ipc.size && ipc.size.length >= 2) ? ipc.size[0] : root.monW
                            readonly property real winH: (ipc && ipc.size && ipc.size.length >= 2) ? ipc.size[1] : root.monH

                            x: isFullscreen ? 2 : Math.max(2, Math.min(wsCell.width - width - 2, Math.round(((winX - root.monX) / Math.max(1, root.monW)) * wsCell.width)))
                            y: isFullscreen ? 2 : Math.max(2, Math.min(wsCell.height - height - 2, Math.round(((winY - root.monY) / Math.max(1, root.monH)) * wsCell.height)))
                            width: isFullscreen ? (wsCell.width - 4) : Math.max(22, Math.min(wsCell.width - 4, Math.round((winW / Math.max(1, root.monW)) * wsCell.width) - 2))
                            height: isFullscreen ? (wsCell.height - 4) : Math.max(18, Math.min(wsCell.height - 4, Math.round((winH / Math.max(1, root.monH)) * wsCell.height) - 2))

                            readonly property string iconSrc: root.resolveIcon(winItem.winClass, winItem.title)

                            opacity: (root.isDragging && root.dragAddress === winItem.address) ? 0.25 : 1.0

                            Rectangle {
                                id: winCard
                                anchors.fill: parent
                                radius: Math.round(5 * root.s)
                                color: (winItem.isSelectedWin && wsCell.isSelected) ? Theme.ghost : (winArea.containsMouse ? Theme.ghost : Theme.cardBot)
                                border.color: (winItem.isSelectedWin && wsCell.isSelected) ? Theme.cream : (winArea.containsMouse ? Theme.vermLit : (wsCell.isSelected ? Theme.hair : Theme.hairSoft))
                                border.width: (winItem.isSelectedWin && wsCell.isSelected) ? 2 : (winArea.containsMouse ? 1.5 : 1)
                                clip: true

                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                // Live real-time window preview
                                ScreencopyView {
                                    id: screencopy
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    captureSource: winItem.waylandTl
                                    live: root.open
                                    paintCursor: false
                                    visible: screencopy.hasContent
                                    opacity: winArea.containsMouse ? 1.0 : 0.88

                                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                                }

                                // Subtle dark veil over live preview so icons and borders pop
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#000000"
                                    visible: screencopy.hasContent
                                    opacity: winArea.containsMouse ? 0.12 : 0.28
                                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                                }

                                // Centered app icon overlay
                                Image {
                                    id: iconImg
                                    anchors.centerIn: parent
                                    readonly property real maxDim: screencopy.hasContent ? Math.min(winItem.width * 0.48, winItem.height * 0.48, 28 * root.s) : Math.min(winItem.width * 0.60, winItem.height * 0.60, 30 * root.s)
                                    width: Math.max(14, maxDim)
                                    height: width
                                    sourceSize.width: Math.round(width * 2)
                                    sourceSize.height: Math.round(height * 2)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    source: winItem.iconSrc
                                    opacity: winArea.containsMouse ? 1.0 : (screencopy.hasContent ? 0.95 : 0.90)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !screencopy.hasContent && (iconImg.status === Image.Error || iconImg.status === Image.Null || winItem.iconSrc.length === 0)
                                    text: winItem.winClass.length > 0 ? winItem.winClass.substring(0, 3).toUpperCase() : "WIN"
                                    font.family: Theme.font
                                    font.pixelSize: Math.max(8, Math.round(winItem.height * 0.35))
                                    font.bold: true
                                    color: Theme.subtle
                                }
                            }

                            MouseArea {
                                id: winArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                                property real startX: 0
                                property real startY: 0
                                property bool dragStarted: false

                                onPressed: (mouse) => {
                                    startX = mouse.x;
                                    startY = mouse.y;
                                    dragStarted = false;
                                }

                                onPositionChanged: (mouse) => {
                                    if (!pressed) return;
                                    var dx = mouse.x - startX;
                                    var dy = mouse.y - startY;
                                    if (!dragStarted && (Math.abs(dx) > 4 || Math.abs(dy) > 4)) {
                                        dragStarted = true;
                                        root.isDragging = true;
                                        root.dragAddress = winItem.address;
                                        root.dragTitle = winItem.title;
                                        root.dragClass = winItem.winClass;
                                        root.dragIconSrc = winItem.iconSrc;
                                        root.dragFromWs = wsCell.wsId;
                                        root.dragW = winItem.width;
                                        root.dragH = winItem.height;
                                    }
                                    if (dragStarted) {
                                        var rootPt = winItem.mapToItem(root, mouse.x, mouse.y);
                                        root.dragX = rootPt.x;
                                        root.dragY = rootPt.y;
                                        root.dropTargetWs = root.getWorkspaceAt(rootPt.x, rootPt.y);
                                    }
                                }

                                onReleased: (mouse) => {
                                    if (dragStarted) {
                                        var targetWs = root.dropTargetWs;
                                        if (targetWs > 0 && targetWs <= 10 && targetWs !== root.dragFromWs) {
                                            root.moveWindowToWorkspace(root.dragAddress, targetWs);
                                        }
                                        root.isDragging = false;
                                        root.dragAddress = "";
                                        root.dropTargetWs = -1;
                                        dragStarted = false;
                                    } else {
                                        root.selectWindow(winItem.address, wsCell.wsId);
                                    }
                                }

                                onCanceled: {
                                    root.isDragging = false;
                                    root.dragAddress = "";
                                    root.dropTargetWs = -1;
                                    dragStarted = false;
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: wsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    z: -1
                    onClicked: {
                        if (!root.isDragging) {
                            root.selectWorkspace(wsCell.wsId);
                        }
                    }
                }
            }
        }
    }

    // Floating drag proxy item
    Item {
        id: dragProxy
        visible: root.isDragging
        z: 200
        x: Math.round(root.dragX - width / 2)
        y: Math.round(root.dragY - height / 2)
        width: Math.max(55 * root.s, Math.round(root.dragW))
        height: Math.max(36 * root.s, Math.round(root.dragH))

        Rectangle {
            anchors.fill: parent
            radius: Math.round(6 * root.s)
            color: Theme.ghost
            border.color: Theme.vermLit
            border.width: 2
            opacity: 0.95

            Image {
                anchors.centerIn: parent
                width: Math.max(16, Math.min(26 * root.s, parent.width * 0.55))
                height: width
                sourceSize.width: Math.round(width * 2)
                sourceSize.height: Math.round(height * 2)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                source: root.dragIconSrc
            }
        }
    }
}

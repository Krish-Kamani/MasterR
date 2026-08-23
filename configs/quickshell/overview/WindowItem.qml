pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    required property var windowData
    required property real cellWidth
    required property real cellHeight
    required property real monWidth
    required property real monHeight
    required property real monX
    required property real monY
    required property int workspaceId

    signal windowClicked(string address, int wsId)

    readonly property var ipc: windowData ? (windowData.lastIpcObject || windowData) : null
    readonly property string address: (windowData && windowData.address) ? windowData.address : (ipc ? ipc.address : "")
    readonly property string title: (windowData && windowData.title) ? windowData.title : (ipc ? ipc.title : "")
    readonly property string winClass: (ipc && ipc.class) ? ipc.class : ((windowData && windowData.wayland && windowData.wayland.appId) ? windowData.wayland.appId : "")
    readonly property bool isFullscreen: ipc ? (ipc.fullscreen === 1 || ipc.fullscreen === 2) : false

    // Geometry calculation
    readonly property real winX: (ipc && ipc.at && ipc.at.length >= 2) ? ipc.at[0] : 0
    readonly property real winY: (ipc && ipc.at && ipc.at.length >= 2) ? ipc.at[1] : 0
    readonly property real winW: (ipc && ipc.size && ipc.size.length >= 2) ? ipc.size[0] : monWidth
    readonly property real winH: (ipc && ipc.size && ipc.size.length >= 2) ? ipc.size[1] : monHeight

    // Calculated position and size in cell coordinates (with subtle margins)
    x: isFullscreen ? 3 : Math.max(3, Math.min(cellWidth - width - 3, ((winX - monX) / Math.max(1, monWidth)) * cellWidth + 1.5))
    y: isFullscreen ? 3 : Math.max(3, Math.min(cellHeight - height - 3, ((winY - monY) / Math.max(1, monHeight)) * cellHeight + 1.5))
    width: isFullscreen ? (cellWidth - 6) : Math.max(26, Math.min(cellWidth - 6, (winW / Math.max(1, monWidth)) * cellWidth - 3))
    height: isFullscreen ? (cellHeight - 6) : Math.max(22, Math.min(cellHeight - 6, (winH / Math.max(1, monHeight)) * cellHeight - 3))

    function resolveIconPath() {
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

    readonly property string iconSource: resolveIconPath()

    Rectangle {
        id: winCard
        anchors.fill: parent
        radius: 6
        color: mouseArea.containsMouse ? "#2a2a36" : "#191921"
        border.color: mouseArea.containsMouse ? "#ffffff" : "#363644"
        border.width: mouseArea.containsMouse ? 1.5 : 1
        scale: mouseArea.pressed ? 0.94 : (mouseArea.containsMouse ? 1.08 : 1.0)

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        Image {
            id: appIcon
            anchors.centerIn: parent
            readonly property real maxDim: Math.min(root.width * 0.58, root.height * 0.58)
            width: Math.max(14, Math.min(36, maxDim))
            height: width
            sourceSize.width: Math.round(width * 2)
            sourceSize.height: Math.round(height * 2)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            source: root.iconSource
            opacity: mouseArea.containsMouse ? 1.0 : 0.92

            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        Text {
            anchors.centerIn: parent
            visible: (appIcon.status === Image.Error || appIcon.status === Image.Null || root.iconSource.length === 0)
            text: root.winClass.length > 0 ? root.winClass.substring(0, 3).toUpperCase() : "WIN"
            font.pixelSize: Math.max(9, Math.round(root.height * 0.35))
            font.bold: true
            color: "#888899"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.windowClicked(root.address, root.workspaceId);
        }
    }
}

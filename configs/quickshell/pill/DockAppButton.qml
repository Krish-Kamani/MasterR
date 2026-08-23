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
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 30 * s
    property real countDotWidth: 10 * s
    property real countDotHeight: 3 * s

    property bool isDragging: false
    property real dragOffsetX: 0

    readonly property bool isSeparator: appToplevel && appToplevel.appId === "SEPARATOR"
    readonly property var toplevelsList: appToplevel ? (appToplevel.toplevels || []) : []
    readonly property int windowCount: toplevelsList.length
    readonly property bool appIsActive: {
        for (var i = 0; i < windowCount; i++) {
            if (toplevelsList[i] && toplevelsList[i].activated)
                return true;
        }
        return false;
    }

    property var desktopEntry: {
        if (!appToplevel || isSeparator) return null;
        var rawId = appToplevel.appId;
        if (!rawId) return null;

        var e = DesktopEntries.heuristicLookup(rawId);
        if (e) return e;

        var idLower = rawId.toLowerCase().replace(/\.desktop$/, "");
        var apps = DesktopEntries.applications.values;
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            if (!a) continue;
            var aid = (a.id || "").toLowerCase().replace(/\.desktop$/, "");
            var aname = (a.name || "").toLowerCase();
            var aexec = (a.exec || "").toLowerCase();
            if (aid === idLower || aname === idLower || aexec.indexOf(idLower) === 0)
                return a;
        }
        for (var j = 0; j < apps.length; j++) {
            var b = apps[j];
            if (!b) continue;
            var bid = (b.id || "").toLowerCase();
            if (bid.indexOf(idLower) !== -1 || idLower.indexOf(bid) !== -1)
                return b;
        }
        return null;
    }

    readonly property string resolvedIcon: {
        if (isSeparator) return "";
        if (desktopEntry && desktopEntry.icon) {
            var iconVal = desktopEntry.icon;
            if (iconVal.indexOf("/") === 0 || iconVal.indexOf("file://") === 0)
                return iconVal;
            var p = Quickshell.iconPath(iconVal, "");
            if (p && p.length > 0) return p;
        }
        if (appToplevel && appToplevel.appId) {
            var raw = appToplevel.appId;
            if (raw.toLowerCase().indexOf("antigravity") !== -1) {
                return "/opt/antigravity/antigravity.png";
            }
            var p2 = Quickshell.iconPath(raw, "");
            if (p2 && p2.length > 0) return p2;
            var clean = raw.toLowerCase().replace(/\.desktop$/, "").replace(/^org\.(kde|gnome|mozilla)\./, "");
            var p3 = Quickshell.iconPath(clean, "");
            if (p3 && p3.length > 0) return p3;
        }
        return Quickshell.iconPath("application-x-executable", "");
    }

    readonly property string appName: {
        if (desktopEntry && desktopEntry.name && desktopEntry.name.length > 0)
            return desktopEntry.name;
        if (appToplevel && appToplevel.appId && !isSeparator) {
            var raw = appToplevel.appId;
            var cleanMap = {
                "com.mitchellh.ghostty": "Ghostty",
                "ghostty": "Ghostty",
                "kitty": "Kitty",
                "org.kde.dolphin": "Dolphin",
                "dolphin": "Dolphin",
                "org.gnome.nautilus": "Files",
                "nautilus": "Files",
                "zen": "Zen Browser",
                "zen-browser": "Zen Browser",
                "app.zen_browser.zen": "Zen Browser",
                "firefox": "Firefox",
                "org.mozilla.firefox": "Firefox",
                "google-chrome": "Google Chrome",
                "chromium": "Chromium",
                "code": "Visual Studio Code",
                "visual-studio-code": "Visual Studio Code",
                "spotify": "Spotify",
                "discord": "Discord",
                "vesktop": "Vesktop",
                "antigravity": "Google Antigravity"
            };
            var lower = raw.toLowerCase().replace(/\.desktop$/, "");
            if (cleanMap[lower]) return cleanMap[lower];

            var stripped = raw.replace(/\.desktop$/, "");
            if (stripped.indexOf(".") !== -1) {
                var parts = stripped.split(".");
                stripped = parts[parts.length - 1];
            }
            return stripped.charAt(0).toUpperCase() + stripped.slice(1);
        }
        return "";
    }

    function launchApp() {
        if (desktopEntry && typeof desktopEntry.execute === "function") {
            desktopEntry.execute();
            return;
        }
        var id = appToplevel ? appToplevel.appId : "";
        if (!id) return;

        var map = {
            "org.kde.dolphin": "dolphin",
            "org.gnome.nautilus": "nautilus",
            "kitty": "kitty",
            "ghostty": "ghostty",
            "com.mitchellh.ghostty": "ghostty",
            "zen": "zen-browser",
            "zen-browser": "zen-browser",
            "app.zen_browser.zen": "zen-browser",
            "firefox": "firefox",
            "org.mozilla.firefox": "firefox",
            "google-chrome": "google-chrome-stable",
            "chromium": "chromium",
            "spotify": "spotify",
            "discord": "discord",
            "vesktop": "vesktop",
            "code": "code",
            "visual-studio-code": "code",
            "android-studio": "android-studio"
        };

        var bin = map[id.toLowerCase()] || id.replace(/\.desktop$/, "");
        Hyprland.dispatch('hl.dsp.exec("' + bin + '")');
    }

    function activateWindow(index) {
        if (windowCount === 0) {
            launchApp();
            return;
        }
        var targetIdx = (typeof index === "number" && index >= 0 && index < windowCount)
            ? index : ((lastFocused + 1) % windowCount);
        lastFocused = targetIdx;
        var tl = toplevelsList[targetIdx];
        if (!tl) return;

        if (typeof tl.activate === "function") {
            tl.activate();
        }

        var addr = tl.address || (tl.lastIpcObject ? tl.lastIpcObject.address : "");
        if (addr) {
            if (addr.indexOf("0x") !== 0) addr = "0x" + addr;
            Hyprland.dispatch('hl.dsp.focuswindow("address:' + addr + '")');
        }
    }

    width: isSeparator ? 1 : 44 * s
    height: 44 * s
    z: root.isDragging ? 100 : 1

    Loader {
        anchors.centerIn: parent
        active: root.isSeparator
        sourceComponent: DockSeparator { s: root.s }
    }

    Rectangle {
        id: bgHighlight
        anchors.fill: parent
        anchors.margins: 2 * root.s
        radius: 8 * root.s
        x: root.dragOffsetX
        opacity: (!root.isSeparator && (mouseArea.containsMouse || root.appIsActive || root.isDragging)) ? 1.0 : 0.0
        scale: root.isDragging ? 1.05 : (mouseArea.isPressed ? 0.95 : (mouseArea.containsMouse ? 1.02 : 0.98))
        color: root.isDragging
            ? Qt.alpha(Theme.onGlow, 0.25)
            : (root.appIsActive
                ? Qt.alpha(Theme.onGlow, 0.14)
                : (mouseArea.containsMouse ? Theme.frameBg : "transparent"))
        border.width: 1
        border.color: root.isDragging
            ? Theme.onGlow
            : (root.appIsActive ? Qt.alpha(Theme.onGlow, 0.28) : Theme.frameBorder)

        Behavior on opacity { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on border.color { ColorAnimation { duration: Motion.fast } }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        visible: !root.isSeparator
        x: root.dragOffsetX
        scale: root.isDragging ? 1.18 : (mouseArea.isPressed ? 0.88 : (mouseArea.containsMouse ? 1.12 : 1.0))

        Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutBack } }

        Image {
            id: appIcon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.windowCount > 0 ? -2 * root.s : 0
            width: root.iconSize
            height: root.iconSize
            sourceSize.width: Math.round(root.iconSize * 2)
            sourceSize.height: Math.round(root.iconSize * 2)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            source: root.resolvedIcon
            opacity: root.appIsActive ? 1.0 : (mouseArea.containsMouse ? 0.95 : 0.85)

            layer.enabled: Flags.dockMonochromeIcons
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: Theme.onGlow
            }

            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        // Running window indicator dots / pill
        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3 * root.s
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2 * root.s
            visible: root.windowCount > 0

            Repeater {
                model: Math.min(root.windowCount, 4)

                delegate: Rectangle {
                    required property int index
                    readonly property bool isCurrentActive: root.appIsActive && (index === 0 || root.windowCount === 1)
                    width: (root.windowCount === 1)
                        ? (isCurrentActive ? 12 * root.s : 5 * root.s)
                        : (root.windowCount <= 3 ? 6 * root.s : 3.5 * root.s)
                    height: root.countDotHeight
                    radius: root.countDotHeight / 2
                    color: isCurrentActive ? Theme.onGlow : Theme.subtle

                    Behavior on width { NumberAnimation { duration: Motion.fast } }
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.isSeparator
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property bool isPressed: false
        property real startPressX: 0

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                isPressed = true;
                startPressX = mouse.x;
                root.dragOffsetX = 0;
            }
        }

        onPositionChanged: (mouse) => {
            if (!isPressed) return;
            var delta = mouse.x - startPressX;
            if (!root.isDragging && Math.abs(delta) > 5 * root.s) {
                root.isDragging = true;
                if (root.appListRoot) {
                    root.appListRoot.draggingButton = root;
                }
            }
            if (root.isDragging) {
                root.dragOffsetX = delta;
                var step = root.width + (3 * root.s);
                if (root.dragOffsetX > step * 0.55) {
                    if (root.appListRoot && typeof root.appListRoot.reorderApp === "function") {
                        root.appListRoot.reorderApp(root, 1);
                        startPressX += step;
                        root.dragOffsetX -= step;
                    }
                } else if (root.dragOffsetX < -step * 0.55) {
                    if (root.appListRoot && typeof root.appListRoot.reorderApp === "function") {
                        root.appListRoot.reorderApp(root, -1);
                        startPressX -= step;
                        root.dragOffsetX += step;
                    }
                }
            }
        }

        onReleased: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                var wasDrag = root.isDragging;
                isPressed = false;
                root.isDragging = false;
                root.dragOffsetX = 0;
                if (root.appListRoot && root.appListRoot.draggingButton === root) {
                    root.appListRoot.draggingButton = null;
                }
                if (!wasDrag) {
                    root.activateWindow();
                }
            }
        }

        onEntered: {
            if (root.appListRoot) {
                root.appListRoot.lastHoveredButton = root;
                root.appListRoot.buttonHovered = true;
            }
            root.lastFocused = root.windowCount - 1;
        }

        onExited: {
            if (root.appListRoot && root.appListRoot.lastHoveredButton === root) {
                root.appListRoot.buttonHovered = false;
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.launchApp();
            } else if (mouse.button === Qt.RightButton) {
                if (root.appToplevel && root.appToplevel.appId) {
                    TaskbarApps.togglePin(root.appToplevel.appId);
                }
            }
        }
    }
}

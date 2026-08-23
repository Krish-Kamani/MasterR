pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    function canonicalId(id) {
        if (!id || id === "SEPARATOR") return "";
        var lower = id.toLowerCase().trim().replace(/\.desktop$/, "");
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
            "antigravity": "antigravity",
            "google-antigravity": "antigravity"
        };
        if (aliases[lower]) return aliases[lower];

        var e = DesktopEntries.heuristicLookup(lower);
        if (e && e.id) {
            var eid = e.id.toLowerCase().replace(/\.desktop$/, "");
            if (aliases[eid]) return aliases[eid];
            return eid;
        }

        if (lower.indexOf(".") !== -1) {
            var parts = lower.split(".");
            var last = parts[parts.length - 1];
            if (last.length > 2 && aliases[last]) return aliases[last];
        }
        return lower;
    }

    function isPinned(appId) {
        if (!appId) return false;
        var cId = canonicalId(appId);
        var pinned = Flags.dockPinnedApps || [];
        for (var i = 0; i < pinned.length; i++) {
            if (canonicalId(pinned[i]) === cId)
                return true;
        }
        return false;
    }

    function togglePin(appId) {
        if (!appId || appId === "SEPARATOR") return;
        var cId = canonicalId(appId);
        var pinned = (Flags.dockPinnedApps ? Flags.dockPinnedApps.slice() : []);
        var index = -1;
        for (var i = 0; i < pinned.length; i++) {
            if (canonicalId(pinned[i]) === cId) {
                index = i;
                break;
            }
        }
        if (index !== -1) {
            pinned.splice(index, 1);
        } else {
            pinned.push(appId);
        }
        Flags.dockPinnedApps = pinned;
    }

    function reorderPinnedApp(appId, dir) {
        if (!appId || appId === "SEPARATOR" || !dir) return;
        var cId = canonicalId(appId);
        var pinned = (Flags.dockPinnedApps ? Flags.dockPinnedApps.slice() : []);
        var index = -1;
        for (var i = 0; i < pinned.length; i++) {
            if (canonicalId(pinned[i]) === cId) {
                index = i;
                break;
            }
        }
        if (index === -1) {
            pinned.push(appId);
            index = pinned.length - 1;
        }
        var targetIndex = index + dir;
        if (targetIndex >= 0 && targetIndex < pinned.length) {
            var item = pinned.splice(index, 1)[0];
            pinned.splice(targetIndex, 0, item);
            Flags.dockPinnedApps = pinned;
        }
    }

    property var apps: {
        var map = new Map();

        // 1. Pinned apps (maintains exact order in Flags.dockPinnedApps)
        var pinnedApps = Flags.dockPinnedApps || [];
        for (var i = 0; i < pinnedApps.length; i++) {
            var pId = pinnedApps[i];
            if (!pId) continue;
            var cKey = canonicalId(pId);
            if (!map.has(cKey)) {
                map.set(cKey, {
                    appId: pId,
                    canonicalKey: cKey,
                    pinned: true,
                    toplevels: []
                });
            }
        }

        // 2. Open toplevel windows (from ToplevelManager / Hyprland)
        var toplevels = (typeof ToplevelManager !== "undefined" && ToplevelManager && ToplevelManager.toplevels)
            ? ToplevelManager.toplevels.values : [];

        for (var j = 0; j < toplevels.length; j++) {
            var tl = toplevels[j];
            if (!tl) continue;
            var rawId = tl.appId || (tl.wayland ? tl.wayland.appId : "") || "";
            if (!rawId && tl.title) rawId = tl.title;
            if (!rawId) continue;

            var cTlKey = canonicalId(rawId);
            if (!map.has(cTlKey)) {
                map.set(cTlKey, {
                    appId: rawId,
                    canonicalKey: cTlKey,
                    pinned: false,
                    toplevels: []
                });
            }
            map.get(cTlKey).toplevels.push(tl);
        }

        // 3. Separate into ordered pinned vs running unpinned
        var pinnedList = [];
        var runningUnpinned = [];

        // Add pinned apps in the exact order of Flags.dockPinnedApps
        for (var k = 0; k < pinnedApps.length; k++) {
            var pk = canonicalId(pinnedApps[k] || "");
            if (map.has(pk)) {
                pinnedList.push(map.get(pk));
                map.delete(pk);
            }
        }

        map.forEach(function(value, key) {
            if (value.toplevels.length > 0) {
                runningUnpinned.push(value);
            }
        });

        var result = [];
        for (var p = 0; p < pinnedList.length; p++) {
            result.push(appEntryComp.createObject(null, {
                appId: pinnedList[p].appId,
                toplevels: pinnedList[p].toplevels,
                pinned: true
            }));
        }

        if (pinnedList.length > 0 && runningUnpinned.length > 0) {
            result.push(appEntryComp.createObject(null, {
                appId: "SEPARATOR",
                toplevels: [],
                pinned: false
            }));
        }

        for (var u = 0; u < runningUnpinned.length; u++) {
            result.push(appEntryComp.createObject(null, {
                appId: runningUnpinned[u].appId,
                toplevels: runningUnpinned[u].toplevels,
                pinned: false
            }));
        }

        return result;
    }

    component TaskbarAppEntry: QtObject {
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }

    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}

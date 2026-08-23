pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Singletons"

/**
 * 舷 DOCK settings sub-surface.
 * Configures the bottom application dock: enable toggle, pin modes (fully pinned,
 * smart pin on empty desktop, auto-hide), height, bottom screen gap, window gap,
 * hover reveal, monochrome icons, and interactive pinned apps management (add / remove).
 */
SettingsSurface {
    id: root

    backSurface: "settings"
    implicitHeight: content.implicitHeight

    readonly property var pinOptions: [
        { label: "Always Pinned", value: "always" },
        { label: "Empty Desktop", value: "desktop" },
        { label: "Auto-Hide", value: "autohide" }
    ]

    readonly property var defaultApps: ["org.kde.dolphin", "ghostty", "zen", "kitty", "firefox"]

    property bool addAppOpen: false
    property string appSearchQuery: ""

    readonly property var availableApps: {
        var list = (typeof DesktopEntries !== "undefined" && DesktopEntries && DesktopEntries.applications)
            ? DesktopEntries.applications.values : [];
        var q = root.appSearchQuery.trim().toLowerCase();
        var out = [];
        var seen = {};

        for (var i = 0; i < list.length; i++) {
            var a = list[i];
            if (!a || !a.id) continue;
            var id = a.id;
            if (seen[id]) continue;
            seen[id] = true;

            var name = a.name || id;
            var comment = a.comment || "";
            if (q.length === 0 || name.toLowerCase().indexOf(q) !== -1 || id.toLowerCase().indexOf(q) !== -1 || comment.toLowerCase().indexOf(q) !== -1) {
                out.push({
                    appId: id,
                    name: name,
                    icon: a.icon || id,
                    isPinned: TaskbarApps.isPinned(id)
                });
            }
        }

        out.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });

        return out;
    }

    rows: [
        { item: dockEnRow, kind: "toggle", get: function () { return Flags.dockEnable; }, set: function (v) { Flags.dockEnable = v; } },
        { item: pinModeRow, kind: "seg", vals: ["always", "desktop", "autohide"], get: function () { return Flags.dockPinMode; }, set: function (v) { Flags.dockPinMode = v; } },
        { item: dockHeightRow, kind: "scrub", bump: function (d) { dockHeightScrub.bump(d); } },
        { item: bottomGapRow, kind: "scrub", bump: function (d) { bottomGapScrub.bump(d); } },
        { item: windowGapRow, kind: "scrub", bump: function (d) { windowGapScrub.bump(d); } },
        { item: hoverRevealRow, kind: "toggle", get: function () { return Flags.dockHoverToReveal; }, set: function (v) { Flags.dockHoverToReveal = v; } },
        { item: monoIconsRow, kind: "toggle", get: function () { return Flags.dockMonochromeIcons; }, set: function (v) { Flags.dockMonochromeIcons = v; } }
    ]

    function resolveIcon(appId) {
        if (!appId) return "";
        if (appId.toLowerCase().indexOf("antigravity") !== -1)
            return "/opt/antigravity/antigravity.png";
        var e = DesktopEntries.heuristicLookup(appId);
        if (e && e.icon) {
            var iconVal = e.icon;
            if (iconVal.indexOf("/") === 0 || iconVal.indexOf("file://") === 0)
                return iconVal;
            var p = Quickshell.iconPath(iconVal, "");
            if (p) return p;
        }
        var raw = appId.replace(/\.desktop$/, "");
        var p2 = Quickshell.iconPath(raw, "");
        if (p2) return p2;
        var clean = raw.toLowerCase().replace(/^org\.(kde|gnome|mozilla)\./, "");
        var p3 = Quickshell.iconPath(clean, "");
        if (p3) return p3;
        return Quickshell.iconPath("application-x-executable", "");
    }

    function resolveName(appId) {
        if (!appId) return "";
        var e = DesktopEntries.heuristicLookup(appId);
        if (e && e.name) return e.name;
        var raw = appId.replace(/\.desktop$/, "");
        if (raw.indexOf(".") !== -1) {
            var parts = raw.split(".");
            raw = parts[parts.length - 1];
        }
        return raw.charAt(0).toUpperCase() + raw.slice(1);
    }

    component GroupLabel: Text {
        topPadding: 14 * root.s
        bottomPadding: 6 * root.s
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 8.5 * root.s
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2 * root.s
    }

    component Group: Column {
        id: grp
        property string title: ""
        property bool open: true
        default property alias rows: body.data

        width: parent ? parent.width : 0
        spacing: 0

        Item {
            width: parent.width
            height: gl.implicitHeight

            GroupLabel { id: gl; text: grp.title }

            GlyphIcon {
                anchors.right: parent.right
                anchors.verticalCenter: gl.verticalCenter
                width: 15 * root.s
                height: 15 * root.s
                name: "chevron-down"
                color: Theme.faint
                stroke: 2.0
                rotation: grp.open ? 0 : -90
                Behavior on rotation { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: grp.open = !grp.open
            }
        }

        Item {
            width: parent.width
            height: grp.open ? body.implicitHeight : 0
            clip: true
            Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }

            Column {
                id: body
                width: parent.width
            }
        }
    }

    component FieldRow: Item {
        id: frow
        property string label: ""
        property string caption: ""
        property bool collapsed: false
        default property alias control: ctrl.data

        readonly property bool focused: root.focusRowItem === frow
        readonly property bool expanded: !frow.collapsed && (fhover.hovered || frow.focused)
        readonly property real rowH: 32 * root.s
        readonly property real capH: 16 * root.s

        width: parent ? parent.width : 0
        height: frow.collapsed ? 0 : (frow.rowH + (frow.expanded ? frow.capH : 0))
        clip: true
        Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }

        HoverHandler {
            id: fhover
            onHoveredChanged: if (!frow.collapsed) root.reportRowHover(frow, hovered)
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3 * root.s
            anchors.bottomMargin: 3 * root.s
            radius: 9 * root.s
            color: (fhover.hovered || frow.focused) ? Theme.frameBg : "transparent"
            Behavior on color { ColorAnimation { duration: Motion.fast } }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: ctrl.left
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activateRow(frow)
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 9 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * root.s

            Text {
                text: frow.label
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * root.s
                font.weight: Font.Medium
            }

            Text {
                visible: frow.expanded && frow.caption.length > 0
                text: frow.caption
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Medium
            }
        }

        Item {
            id: ctrl
            anchors.right: parent.right
            anchors.rightMargin: 9 * root.s
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
            z: 10
        }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "舷"
            title: "DOCK"
        }

        // --- Main Enable Row ---
        SettingsRow {
            id: dockEnRow
            surface: root
            captionOnFocus: true
            icon: "apps"
            name: "Bottom dock"
            sub: Flags.dockEnable ? "Dock is active at bottom edge" : "Dock is currently disabled"

            LinkToggle {
                s: root.s
                on: Flags.dockEnable
                onToggled: Flags.dockEnable = !Flags.dockEnable
            }
        }

        // --- Pinning Mode Group ---
        Group {
            id: pinGrp
            title: "Pinning Mode"
            open: true

            FieldRow {
                id: pinModeRow
                label: "Mode"
                caption: Flags.dockPinMode === "always"
                    ? "Always visible; window space reserved"
                    : (Flags.dockPinMode === "desktop"
                        ? "Pinned on empty desktop; auto-hides with windows"
                        : "Hidden by default; hover screen edge to reveal")

                SettingsSeg {
                    s: root.s
                    options: root.pinOptions
                    value: Flags.dockPinMode
                    onPicked: v => { Flags.dockPinMode = v; }
                }
            }
        }

        // --- Geometry & Gaps Group ---
        Group {
            id: behaviorGrp
            title: "Geometry & Gaps"
            open: true

            FieldRow {
                id: dockHeightRow
                label: "Dock height"
                caption: "Vertical height of the dock pill"
                ScrubValue {
                    id: dockHeightScrub
                    s: root.s
                    value: Flags.dockHeight
                    openValue: 52
                    from: 42; to: 72; step: 2; decimals: 0
                    unit: "px"
                    onEdited: v => { Flags.dockHeight = v; }
                }
            }

            FieldRow {
                id: bottomGapRow
                label: "Bottom screen gap"
                caption: "Spacing between dock and bottom screen edge"
                ScrubValue {
                    id: bottomGapScrub
                    s: root.s
                    value: Flags.dockBottomGap !== undefined ? Flags.dockBottomGap : 8
                    openValue: 8
                    from: 0; to: 32; step: 2; decimals: 0
                    unit: "px"
                    onEdited: v => { Flags.dockBottomGap = v; }
                }
            }

            FieldRow {
                id: windowGapRow
                label: "Window gap"
                caption: "Reserved margin between dock and tiled windows"
                collapsed: Flags.dockPinMode === "autohide"
                ScrubValue {
                    id: windowGapScrub
                    s: root.s
                    value: Flags.dockWindowGap !== undefined ? Flags.dockWindowGap : 8
                    openValue: 8
                    from: 0; to: 32; step: 2; decimals: 0
                    unit: "px"
                    onEdited: v => { Flags.dockWindowGap = v; }
                }
            }

            FieldRow {
                id: hoverRevealRow
                label: "Hover reveal"
                caption: "Slide dock in when cursor reaches screen bottom"
                collapsed: Flags.dockPinMode === "always"
                LinkToggle {
                    s: root.s
                    on: Flags.dockHoverToReveal
                    onToggled: Flags.dockHoverToReveal = !Flags.dockHoverToReveal
                }
            }

            FieldRow {
                id: monoIconsRow
                label: "Monochrome icons"
                caption: "Tint app icons with active theme accent"
                LinkToggle {
                    s: root.s
                    on: Flags.dockMonochromeIcons
                    onToggled: Flags.dockMonochromeIcons = !Flags.dockMonochromeIcons
                }
            }
        }

        // --- Pinned Shortcuts Management Group ---
        Group {
            id: appsGrp
            title: "Pinned Shortcuts (" + ((Flags.dockPinnedApps || []).length) + ")"
            open: true

            Column {
                width: parent.width
                spacing: 6 * root.s

                // 1. Current Pinned Apps List
                Repeater {
                    model: Flags.dockPinnedApps || []

                    delegate: Rectangle {
                        id: appTile
                        required property string modelData
                        width: parent.width
                        height: 34 * root.s
                        radius: 7 * root.s
                        color: tileMouse.containsMouse ? Theme.frameBg : "transparent"
                        border.width: 1
                        border.color: tileMouse.containsMouse ? Theme.frameBorder : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8 * root.s
                            anchors.rightMargin: 8 * root.s
                            spacing: 8 * root.s

                            Image {
                                width: 20 * root.s
                                height: 20 * root.s
                                sourceSize.width: Math.round(40 * root.s)
                                sourceSize.height: Math.round(40 * root.s)
                                fillMode: Image.PreserveAspectFit
                                source: root.resolveIcon(appTile.modelData)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.resolveName(appTile.modelData)
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 11 * root.s
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            // Unpin button
                            Rectangle {
                                width: 24 * root.s
                                height: 24 * root.s
                                radius: 12 * root.s
                                color: unpinMouse.containsMouse ? Theme.vermBurn : "transparent"

                                GlyphIcon {
                                    anchors.centerIn: parent
                                    width: 11 * root.s
                                    height: 11 * root.s
                                    name: "close"
                                    color: unpinMouse.containsMouse ? Theme.bright : Theme.subtle
                                    stroke: 2.0
                                }

                                MouseArea {
                                    id: unpinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TaskbarApps.togglePin(appTile.modelData)
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // 2. Add App Button & Search Picker
                Column {
                    width: parent.width
                    spacing: 6 * root.s

                    Rectangle {
                        width: parent.width
                        height: 30 * root.s
                        radius: 7 * root.s
                        color: addMouse.containsMouse ? Theme.frameBg : Qt.alpha(Theme.onGlow, 0.08)
                        border.width: 1
                        border.color: addMouse.containsMouse ? Theme.frameBorder : Qt.alpha(Theme.onGlow, 0.2)

                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6 * root.s

                            GlyphIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12 * root.s
                                height: 12 * root.s
                                name: root.addAppOpen ? "chevron-up" : "sparkles"
                                color: Theme.onGlow
                                stroke: 2.0
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.addAppOpen ? "Close app picker" : "+ Pin application..."
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 11 * root.s
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.addAppOpen = !root.addAppOpen;
                                if (root.addAppOpen) {
                                    searchField.forceActiveFocus();
                                }
                            }
                        }
                    }

                    // Collapsible App Search & Add Picker
                    Item {
                        width: parent.width
                        height: root.addAppOpen ? pickerCol.implicitHeight : 0
                        clip: true
                        Behavior on height { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }

                        Column {
                            id: pickerCol
                            width: parent.width
                            spacing: 6 * root.s

                            // Search bar
                            Rectangle {
                                width: parent.width
                                height: 30 * root.s
                                radius: 6 * root.s
                                color: Theme.tileBg
                                border.width: 1
                                border.color: searchField.activeFocus ? Theme.onGlow : Theme.hair

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8 * root.s
                                    anchors.rightMargin: 8 * root.s
                                    spacing: 6 * root.s

                                    GlyphIcon {
                                        width: 13 * root.s
                                        height: 13 * root.s
                                        name: "search"
                                        color: searchField.activeFocus ? Theme.onGlow : Theme.iconDim
                                        stroke: 1.8
                                    }

                                    TextField {
                                        id: searchField
                                        Layout.fillWidth: true
                                        background: null
                                        padding: 0
                                        color: Theme.cream
                                        font.family: Theme.font
                                        font.pixelSize: 11 * root.s
                                        placeholderText: "Search installed apps to pin..."
                                        placeholderTextColor: Theme.faint
                                        selectByMouse: true
                                        onTextChanged: root.appSearchQuery = text
                                    }
                                }
                            }

                            // App Results List
                            ListView {
                                width: parent.width
                                height: Math.min(180 * root.s, contentHeight)
                                clip: true
                                model: root.availableApps
                                spacing: 3 * root.s

                                delegate: Rectangle {
                                    id: searchItem
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 30 * root.s
                                    radius: 6 * root.s
                                    color: itemMouse.containsMouse ? Theme.frameBg : "transparent"
                                    border.width: 1
                                    border.color: itemMouse.containsMouse ? Theme.frameBorder : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6 * root.s
                                        anchors.rightMargin: 6 * root.s
                                        spacing: 6 * root.s

                                        Image {
                                            width: 18 * root.s
                                            height: 18 * root.s
                                            sourceSize.width: Math.round(36 * root.s)
                                            sourceSize.height: Math.round(36 * root.s)
                                            fillMode: Image.PreserveAspectFit
                                            source: root.resolveIcon(searchItem.modelData.appId)
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: searchItem.modelData.name
                                            color: Theme.cream
                                            font.family: Theme.font
                                            font.pixelSize: 10.5 * root.s
                                            font.weight: Font.Medium
                                            elide: Text.ElideRight
                                        }

                                        // Status badge / Pin Action Button
                                        Rectangle {
                                            width: searchItem.modelData.isPinned ? 52 * root.s : 44 * root.s
                                            height: 20 * root.s
                                            radius: 4 * root.s
                                            color: searchItem.modelData.isPinned ? Qt.alpha(Theme.onGlow, 0.16) : Theme.frameBg
                                            border.width: 1
                                            border.color: searchItem.modelData.isPinned ? Qt.alpha(Theme.onGlow, 0.35) : Theme.hair

                                            Text {
                                                anchors.centerIn: parent
                                                text: searchItem.modelData.isPinned ? "Pinned" : "+ Pin"
                                                color: searchItem.modelData.isPinned ? Theme.onGlow : Theme.cream
                                                font.family: Theme.font
                                                font.pixelSize: 9 * root.s
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: itemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            TaskbarApps.togglePin(searchItem.modelData.appId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Reset Button
                Rectangle {
                    width: parent.width
                    height: 28 * root.s
                    radius: 6 * root.s
                    color: resetMouse.containsMouse ? Theme.frameBg : "transparent"
                    border.width: 1
                    border.color: resetMouse.containsMouse ? Theme.frameBorder : Theme.hair

                    Text {
                        anchors.centerIn: parent
                        text: "Reset pinned apps to default"
                        color: resetMouse.containsMouse ? Theme.cream : Theme.subtle
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Flags.dockPinnedApps = root.defaultApps.slice()
                    }
                }
            }
        }

        Item { width: 1; height: 12 * root.s }
    }
}

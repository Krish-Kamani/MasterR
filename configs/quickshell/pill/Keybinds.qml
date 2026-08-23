pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "lib/binds.js" as Binds
import "lib/keychord.js" as Chord
import "Singletons"

/**
 * 鍵 KEYBINDS surface: fully interactive keyboard shortcut manager extending from
 * the top Pill, featuring 4-column layout (Shortcut, Name, Category Dropdown, Action/Command),
 * category filtering, instant search, draggable vertical scroll panel,
 * direct physical key combination recording, and live synchronization with binds.lua.
 * Styled natively to match the Pill's washi/glass theme.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 16
    mRight: 16
    mBottom: 14

    implicitHeight: content.implicitHeight

    signal requestSurface(string name)

    readonly property string bindsPath: Quickshell.env("HOME") + "/.config/hypr/modules/binds.lua"

    property var binds: []
    property int focusIndex: 0
    property int recordingIndex: -1
    property bool listening: recordingIndex !== -1 || formRecording
    property string activeCategory: "All"
    property string query: ""
    property string conflict: ""

    property bool formOpen: false
    property bool formAdd: false
    property int formLine: -1
    property bool formCmdEditable: true
    property string formAction: ""
    property string formCombo: ""
    property string formName: ""
    property string formCmd: ""
    property string formCategory: "Apps"
    property string origCombo: ""
    property string origName: ""
    property string origCmd: ""
    property string origAction: ""
    property string origCategory: ""
    property bool formRecording: false

    // Category picker popover state
    property var categoryPickerData: null // { lineIndex: int, currentCat: string, x: real, y: real }
    property bool formCategoryDropdownOpen: false

    readonly property var filterCategories: ["All", "Apps", "Window", "Workspaces", "Media", "Launchers", "System"]
    readonly property var availableCategories: ["Apps", "Window", "Workspaces", "Media", "Launchers", "System"]

    /**
     * Binds filtered by active category and search query.
     */
    readonly property var filtered: {
        var list = root.binds;
        if (root.activeCategory !== "All") {
            list = list.filter(function (b) {
                return b.category === root.activeCategory;
            });
        }
        if (root.query.trim().length > 0) {
            var q = root.query.trim().toLowerCase();
            list = list.filter(function (b) {
                var searchTarget = (b.combo + " " + b.label + " " + b.name + " " + b.work + " " + b.cmd + " " + b.action + " " + b.category).toLowerCase();
                return searchTarget.indexOf(q) !== -1;
            });
        }
        return list;
    }

    function comboPretty(c) {
        return Chord.formatPretty(c);
    }

    function refresh() {
        root.binds = Binds.parse(bindsFile.text());
        if (root.focusIndex >= root.filtered.length)
            root.focusIndex = Math.max(0, root.filtered.length - 1);
    }

    function move(dir) {
        if (root.listening || root.formOpen || root.categoryPickerData !== null)
            return;
        if (root.filtered.length === 0)
            return;
        root.focusIndex = Math.max(0, Math.min(root.filtered.length - 1, root.focusIndex + dir));
        list.positionViewAtIndex(root.focusIndex, ListView.Contain);
    }

    function activate() {
        if (root.listening || root.focusIndex < 0 || root.focusIndex >= root.filtered.length)
            return;
        startInlineRecording(root.focusIndex);
    }

    function startInlineRecording(index) {
        root.categoryPickerData = null;
        root.formOpen = false;
        root.conflict = "";
        root.recordingIndex = index;
        root.formRecording = false;
        keyCatcher.forceActiveFocus();
    }

    function startFormRecording() {
        root.conflict = "";
        root.formRecording = true;
        root.recordingIndex = -1;
        keyCatcher.forceActiveFocus();
    }

    function cancelRecording() {
        root.recordingIndex = -1;
        root.formRecording = false;
        root.conflict = "";
        searchInput.forceActiveFocus();
    }

    function openEdit(b) {
        if (b.isMouse)
            return;
        root.categoryPickerData = null;
        root.conflict = "";
        root.recordingIndex = -1;
        root.formRecording = false;
        root.formAdd = false;
        root.formLine = b.lineIndex;
        root.formCmdEditable = b.isExec && b.cmd.length > 0;
        root.formAction = b.action;
        root.formCombo = b.combo;
        root.formName = b.explicitName || b.label;
        root.formCmd = b.cmd.length > 0 ? b.cmd : b.action;
        root.formCategory = b.category || "Apps";
        root.origCombo = b.combo;
        root.origName = b.explicitName || b.label;
        root.origCmd = b.cmd;
        root.origAction = b.action;
        root.origCategory = b.category || "Apps";
        root.formOpen = true;
        Qt.callLater(nameField.forceActiveFocus);
    }

    function openAdd() {
        root.categoryPickerData = null;
        root.conflict = "";
        root.recordingIndex = -1;
        root.formRecording = false;
        root.formAdd = true;
        root.formLine = -1;
        root.formCmdEditable = true;
        root.formAction = "";
        root.formCombo = "";
        root.formName = "";
        root.formCmd = "";
        root.formCategory = (root.activeCategory !== "All") ? root.activeCategory : "Apps";
        root.origCombo = "";
        root.origName = "";
        root.origCmd = "";
        root.origAction = "";
        root.origCategory = "";
        root.formOpen = true;
        Qt.callLater(nameField.forceActiveFocus);
    }

    function closeForm() {
        root.formOpen = false;
        root.formCategoryDropdownOpen = false;
        root.recordingIndex = -1;
        root.formRecording = false;
        root.conflict = "";
    }

    function openCategoryDropdown(lineIndex, currentCat, targetItem) {
        var pt = targetItem.mapToItem(root, 0, targetItem.height + 4 * root.s);
        var targetX = Math.max(8 * root.s, Math.min(root.width - 125 * root.s, pt.x));
        var targetY = pt.y;
        if (targetY + 160 * root.s > root.height) {
            targetY = pt.y - targetItem.height - 165 * root.s;
        }
        root.categoryPickerData = {
            lineIndex: lineIndex,
            currentCat: currentCat,
            x: targetX,
            y: targetY
        };
    }

    function setCategoryForBind(lineIndex, newCat) {
        root.categoryPickerData = null;
        var r = Binds.editCategory(bindsFile.text(), lineIndex, newCat);
        if (!r.ok) {
            root.conflict = r.error || "failed to update category";
            return;
        }
        writer.setText(r.text);
    }

    function capture(key, modifiers) {
        if (key === Qt.Key_Escape) {
            cancelRecording();
            return;
        }

        var combo = Chord.chord(key, modifiers);
        if (combo === null)
            return;

        if (root.formRecording) {
            root.formCombo = combo;
            root.formRecording = false;
            root.conflict = "";
            Qt.callLater(nameField.forceActiveFocus);
            return;
        }

        if (root.recordingIndex >= 0 && root.recordingIndex < root.filtered.length) {
            var targetBind = root.filtered[root.recordingIndex];
            var text = bindsFile.text();

            if (Binds.inUse(text, combo, targetBind.lineIndex)) {
                root.conflict = combo + " already bound!";
                root.cancelRecording();
                return;
            }

            var r = Binds.rebind(text, targetBind.lineIndex, combo);
            if (!r.ok) {
                root.conflict = r.error || "rebind failed";
                root.cancelRecording();
                return;
            }

            writer.setText(r.text);
        }
    }

    function save() {
        var text = bindsFile.text();
        if (root.formAdd) {
            if (root.formCombo.length === 0) { root.conflict = "pick a key shortcut"; return; }
            if (root.formCmd.length === 0) { root.conflict = "command empty"; return; }
            if (Binds.inUse(text, root.formCombo, -1)) {
                root.conflict = root.formCombo + " already bound";
                return;
            }
            var a = Binds.add(text, root.formCombo, root.formCmd.trim(), root.formName.trim(), root.formCategory);
            if (!a.ok) { root.conflict = a.error || "add failed"; return; }
            writer.setText(a.text);
            return;
        }

        if (root.formCombo !== root.origCombo && Binds.inUse(text, root.formCombo, root.formLine)) {
            root.conflict = root.formCombo + " already bound";
            return;
        }

        var out = text;
        if (root.formCombo !== root.origCombo) {
            var r = Binds.rebind(out, root.formLine, root.formCombo);
            if (!r.ok) { root.conflict = r.error || "rebind failed"; return; }
            out = r.text;
        }
        if (root.formCmdEditable && root.formCmd !== root.origCmd) {
            if (root.formCmd.length === 0) { root.conflict = "command empty"; return; }
            var c = Binds.editCmd(out, root.formLine, root.formCmd.trim());
            if (!c.ok) { root.conflict = c.error || "command edit failed"; return; }
            out = c.text;
        }
        if (root.formName !== root.origName) {
            var n = Binds.editName(out, root.formLine, root.formName.trim());
            if (!n.ok) { root.conflict = n.error || "name edit failed"; return; }
            out = n.text;
        }
        if (root.formCategory !== root.origCategory) {
            var catRes = Binds.editCategory(out, root.formLine, root.formCategory);
            if (!catRes.ok) { root.conflict = catRes.error || "category edit failed"; return; }
            out = catRes.text;
        }

        if (out === text) {
            closeForm();
            return;
        }
        writer.setText(out);
    }

    function removeBind() {
        if (root.formAdd || root.formLine < 0)
            return;
        var d = Binds.del(bindsFile.text(), root.formLine);
        if (!d.ok) { root.conflict = d.error || "delete failed"; return; }
        writer.setText(d.text);
    }

    onActiveChanged: {
        if (active) {
            bindsFile.reload();
            refresh();
            focusIndex = 0;
            recordingIndex = -1;
            formRecording = false;
            query = "";
            activeCategory = "All";
            categoryPickerData = null;
            formCategoryDropdownOpen = false;
            formOpen = false;
            conflict = "";
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            recordingIndex = -1;
            formRecording = false;
            formOpen = false;
            categoryPickerData = null;
            formCategoryDropdownOpen = false;
            conflict = "";
        }
    }

    onFormOpenChanged: if (formOpen) Qt.callLater(nameField.forceActiveFocus)

    readonly property Item focusRowItem: list.focusRowItem
    readonly property bool rowFocused: focusRowItem !== null && active && !formOpen

    readonly property point rowPoint: {
        void root.width;
        void root.height;
        void root.focusIndex;
        void list.contentY;
        if (!focusRowItem)
            return Qt.point(4 * root.s, root.height / 2);
        return focusRowItem.mapToItem(root, 4 * root.s, focusRowItem.height / 2);
    }

    ameForm: rowFocused ? "rowseam" : "off"
    amePoint: rowPoint

    FileView {
        id: bindsFile
        path: root.bindsPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.refresh()
        onFileChanged: reload()
    }

    FileView {
        id: writer
        path: root.bindsPath
        atomicWrites: true
        printErrors: false
        onSaved: {
            reloadProc.running = true;
            root.formOpen = false;
            root.recordingIndex = -1;
            root.formRecording = false;
            root.categoryPickerData = null;
            root.conflict = "";
            bindsFile.reload();
            root.refresh();
        }
        onSaveFailed: (err) => {
            root.conflict = "write failed: " + err;
        }
    }

    Process {
        id: reloadProc
        command: ["setsid", "-f", "sh", "-c", "sleep 0.2; hyprctl reload"]
    }

    Item {
        id: keyCatcher
        focus: root.listening
        Keys.onPressed: (e) => {
            if (!root.listening)
                return;
            e.accepted = true;
            root.capture(e.key, e.modifiers);
        }
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Header Bar
        Item {
            width: parent.width
            height: 28 * root.s

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "鍵"
                    color: Theme.vermLit
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 18 * root.s
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "KEYBINDS"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.6 * root.s
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: countLabel.implicitWidth + 12 * root.s
                    height: 18 * root.s
                    radius: 9 * root.s
                    color: Qt.alpha(Theme.cream, 0.05)
                    border.width: 1
                    border.color: Theme.hairSoft

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: root.filtered.length + (root.filtered.length === 1 ? " bind" : " binds")
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 9.5 * root.s
                        font.weight: Font.Medium
                    }
                }
            }

            // Right side: Add Bind button & Back chevron
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.formOpen
                    width: addBtnLabel.implicitWidth + 18 * root.s
                    height: 22 * root.s
                    radius: 6 * root.s
                    color: addPillHover.hovered ? Theme.vermLit : Qt.alpha(Theme.verm, 0.18)
                    border.width: 1
                    border.color: addPillHover.hovered ? Theme.vermLit : Qt.alpha(Theme.vermLit, 0.4)
                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 4 * root.s

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "+"
                            color: addPillHover.hovered ? Theme.cream : Theme.vermLit
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: Font.Bold
                        }

                        Text {
                            id: addBtnLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Add Bind"
                            color: addPillHover.hovered ? Theme.cream : Theme.vermLit
                            font.family: Theme.font
                            font.pixelSize: 10 * root.s
                            font.weight: Font.Bold
                            font.letterSpacing: 0.4 * root.s
                        }
                    }

                    HoverHandler { id: addPillHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openAdd()
                    }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * root.s
                    height: 20 * root.s

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 15 * root.s
                        height: 15 * root.s
                        name: "chevron-left"
                        color: chevronHover.hovered ? Theme.cream : Theme.iconDim
                        stroke: 2.0
                    }

                    HoverHandler { id: chevronHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.formOpen) root.closeForm();
                            else root.requestClose();
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: root.formOpen ? 0 : 8 * root.s
        }

        // Search Input (Transparent Pill Styling)
        Item {
            width: parent.width
            height: 30 * root.s
            visible: !root.formOpen

            Text {
                id: searchGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: Flags.showGlyphs
                text: "探"
                color: Theme.dim
                font.family: Theme.fontJp
                font.weight: Font.Medium
                font.pixelSize: 15 * root.s
            }

            TextField {
                id: searchInput
                anchors.left: searchGlyph.visible ? searchGlyph.right : parent.left
                anchors.leftMargin: searchGlyph.visible ? 10 * root.s : 0
                anchors.right: clearBtn.visible ? clearBtn.left : parent.right
                anchors.rightMargin: 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                background: null
                padding: 0
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 13.5 * root.s
                placeholderText: "search by name, shortcut, or command..."
                placeholderTextColor: Theme.faint
                selectByMouse: true
                selectionColor: Theme.verm
                text: root.query
                onTextChanged: {
                    root.query = text;
                    root.focusIndex = 0;
                }
                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onPressed: (e) => {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        root.activate();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Escape) {
                        root.requestClose();
                        e.accepted = true;
                    }
                }
            }

            Rectangle {
                anchors.left: searchInput.left
                anchors.right: parent.right
                anchors.top: searchInput.bottom
                anchors.topMargin: 2 * root.s
                height: 1
                color: Theme.vermLit
                opacity: searchInput.activeFocus ? 0.7 : 0.2
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            }

            Text {
                id: clearBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.query.length > 0
                text: "✕"
                color: clearHover.hovered ? Theme.cream : Theme.dim
                font.pixelSize: 11 * root.s
                HoverHandler { id: clearHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.query = "";
                        searchInput.forceActiveFocus();
                    }
                }
            }
        }

        Item {
            width: 1
            height: root.formOpen ? 0 : 8 * root.s
        }

        // Category filter chips
        Row {
            width: parent.width
            visible: !root.formOpen
            spacing: 6 * root.s

            Repeater {
                model: root.filterCategories
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool isActive: root.activeCategory === modelData

                    height: 22 * root.s
                    width: catText.implicitWidth + 14 * root.s
                    radius: 6 * root.s
                    color: isActive ? Qt.alpha(Theme.vermLit, 0.22)
                         : (catChipHover.hovered ? Qt.alpha(Theme.cream, 0.07) : "transparent")
                    border.width: 1
                    border.color: isActive ? Theme.vermLit : (catChipHover.hovered ? Theme.subtle : Theme.hairSoft)
                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                    Text {
                        id: catText
                        anchors.centerIn: parent
                        text: modelData
                        color: isActive ? Theme.vermLit : (catChipHover.hovered ? Theme.cream : Theme.dim)
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: isActive ? Font.Bold : Font.Medium
                    }

                    HoverHandler { id: catChipHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeCategory = modelData;
                            root.focusIndex = 0;
                        }
                    }
                }
            }
        }

        // Divider Line
        Rectangle {
            width: parent.width
            height: 1
            visible: !root.formOpen
            color: Theme.hair
            anchors.topMargin: 8 * root.s
        }

        Item {
            width: 1
            height: root.formOpen ? 0 : 6 * root.s
        }

        // Recording Notification Banner
        Rectangle {
            id: recordingBanner
            visible: root.recordingIndex !== -1 && !root.formOpen
            width: parent.width
            height: visible ? 32 * root.s : 0
            radius: 7 * root.s
            color: Qt.alpha(Theme.vermLit, 0.16)
            border.width: 1
            border.color: Theme.vermLit

            Row {
                anchors.centerIn: parent
                spacing: 10 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "● RECORDING"
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 10.5 * root.s
                    font.weight: Font.Bold
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Press shortcut keys on your keyboard... (Esc to cancel)"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52 * root.s
                    height: 20 * root.s
                    radius: 5 * root.s
                    color: Qt.alpha(Theme.cardBot, 0.9)
                    border.width: 1
                    border.color: Theme.hairSoft

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 9.5 * root.s
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelRecording()
                    }
                }
            }
        }

        Item {
            width: 1
            height: (root.recordingIndex !== -1 && !root.formOpen) ? 6 * root.s : 0
        }

        // List Container with Integrated Scroll Panel & Category Dropdown
        Item {
            id: listContainer
            width: parent.width
            height: visible ? Math.min(list.contentHeight, 350 * root.s) : 0
            visible: !root.formOpen

            readonly property bool canScroll: list.contentHeight > height
            readonly property real maxScroll: Math.max(0, list.contentHeight - list.height)

            ListView {
                id: list
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: scrollTrack.visible ? scrollTrack.left : parent.right
                anchors.rightMargin: scrollTrack.visible ? 4 * root.s : 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.filtered

                property Item focusRowItem: null

                delegate: Item {
                    id: brow
                    required property int index
                    required property var modelData

                    readonly property bool focused: root.focusIndex === brow.index
                    readonly property bool isThisRecording: root.recordingIndex === brow.index
                    readonly property bool isThisPickerOpen: root.categoryPickerData !== null && root.categoryPickerData.lineIndex === brow.modelData.lineIndex

                    width: ListView.view.width
                    height: 44 * root.s

                    onFocusedChanged: if (focused) list.focusRowItem = brow

                    HoverHandler {
                        id: rowHover
                        onHoveredChanged: if (hovered && !root.listening) root.focusIndex = brow.index
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2 * root.s
                        anchors.bottomMargin: 2 * root.s
                        radius: 8 * root.s
                        color: brow.isThisRecording ? Qt.alpha(Theme.vermLit, 0.18)
                             : ((rowHover.hovered || brow.focused) ? Qt.alpha(Theme.cream, 0.055) : "transparent")
                        border.width: brow.isThisRecording || brow.focused ? 1 : 0
                        border.color: brow.isThisRecording ? Theme.vermLit : Qt.alpha(Theme.vermLit, 0.3)
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }

                    // 1. Left: Shortcut Key Chip
                    Item {
                        id: chipCol
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 175 * root.s
                        height: parent.height

                        Rectangle {
                            id: comboChip
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(parent.width - 4 * root.s, comboText.implicitWidth + 20 * root.s)
                            height: 28 * root.s
                            radius: 6 * root.s
                            color: brow.isThisRecording ? Qt.alpha(Theme.vermLit, 0.28)
                                 : (brow.focused ? Qt.alpha(Theme.cream, 0.09) : Qt.alpha(Theme.cream, 0.045))
                            border.width: 1
                            border.color: brow.isThisRecording ? Theme.vermLit
                                        : (brow.focused ? Qt.alpha(Theme.vermLit, 0.5) : Theme.hairSoft)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5 * root.s

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: brow.isThisRecording ? "●" : "⌨"
                                    color: brow.isThisRecording ? Theme.vermLit : (brow.focused ? Theme.vermLit : Theme.dim)
                                    font.pixelSize: 10 * root.s
                                }

                                Text {
                                    id: comboText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: brow.isThisRecording ? "Press keys..." : root.comboPretty(brow.modelData.combo)
                                    color: brow.isThisRecording ? Theme.vermLit : (brow.focused ? Theme.bright : Theme.cream)
                                    font.family: Theme.font
                                    font.pixelSize: 11.5 * root.s
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.2 * root.s
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !brow.modelData.isMouse
                                cursorShape: brow.modelData.isMouse ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    root.focusIndex = brow.index;
                                    root.startInlineRecording(brow.index);
                                }
                            }
                        }
                    }

                    // 2. Middle-Left: Name Title & Work Subtitle
                    Column {
                        id: nameCol
                        anchors.left: chipCol.right
                        anchors.leftMargin: 8 * root.s
                        anchors.right: catSelectorCol.left
                        anchors.rightMargin: 8 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2 * root.s

                        Text {
                            width: parent.width
                            text: brow.modelData.label || brow.modelData.name || "Shortcut"
                            color: brow.focused ? Theme.bright : Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: brow.modelData.work || brow.modelData.cmd || brow.modelData.action
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10 * root.s
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                        }
                    }

                    // 3. Category Selector Dropdown Chip (The vertical rectangle area)
                    Item {
                        id: catSelectorCol
                        anchors.right: rowActions.left
                        anchors.rightMargin: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 95 * root.s
                        height: 24 * root.s

                        Rectangle {
                            id: catChip
                            anchors.fill: parent
                            radius: 6 * root.s
                            color: brow.isThisPickerOpen ? Qt.alpha(Theme.vermLit, 0.22)
                                 : (catChipHover.hovered ? Qt.alpha(Theme.cream, 0.09) : Qt.alpha(Theme.cream, 0.045))
                            border.width: 1
                            border.color: brow.isThisPickerOpen ? Theme.vermLit
                                        : (catChipHover.hovered ? Theme.subtle : Theme.hairSoft)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5 * root.s

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: brow.modelData.category || "Apps"
                                    color: brow.isThisPickerOpen ? Theme.vermLit : (catChipHover.hovered ? Theme.cream : Theme.dim)
                                    font.family: Theme.font
                                    font.pixelSize: 10 * root.s
                                    font.weight: Font.Medium
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "▾"
                                    color: brow.isThisPickerOpen ? Theme.vermLit : (catChipHover.hovered ? Theme.cream : Theme.faint)
                                    font.pixelSize: 9 * root.s
                                }
                            }

                            HoverHandler { id: catChipHover }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !brow.modelData.isMouse
                                cursorShape: brow.modelData.isMouse ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (brow.isThisPickerOpen) {
                                        root.categoryPickerData = null;
                                    } else {
                                        root.openCategoryDropdown(brow.modelData.lineIndex, brow.modelData.category || "Apps", catChip);
                                    }
                                }
                            }
                        }
                    }

                    // 4. Right: Action Buttons (Rebind, Edit, Delete)
                    Row {
                        id: rowActions
                        anchors.right: parent.right
                        anchors.rightMargin: 6 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * root.s
                        opacity: (rowHover.hovered || brow.focused || brow.isThisRecording || brow.isThisPickerOpen) ? 1.0 : 0.3
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                        // Rebind Button
                        Rectangle {
                            visible: !brow.modelData.isMouse
                            width: rebindLabel.implicitWidth + 14 * root.s
                            height: 24 * root.s
                            radius: 5 * root.s
                            color: rebindHover.hovered ? Qt.alpha(Theme.vermLit, 0.22) : Qt.alpha(Theme.cream, 0.045)
                            border.width: 1
                            border.color: rebindHover.hovered ? Theme.vermLit : Theme.hairSoft
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                id: rebindLabel
                                anchors.centerIn: parent
                                text: "Rebind"
                                color: rebindHover.hovered ? Theme.vermLit : Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                                font.weight: Font.Medium
                            }

                            HoverHandler { id: rebindHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.focusIndex = brow.index;
                                    root.startInlineRecording(brow.index);
                                }
                            }
                        }

                        // Edit Button
                        Rectangle {
                            visible: !brow.modelData.isMouse
                            width: 24 * root.s
                            height: 24 * root.s
                            radius: 5 * root.s
                            color: editBtnHover.hovered ? Qt.alpha(Theme.cream, 0.1) : Qt.alpha(Theme.cream, 0.045)
                            border.width: 1
                            border.color: editBtnHover.hovered ? Theme.cream : Theme.hairSoft
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                anchors.centerIn: parent
                                text: "✎"
                                color: editBtnHover.hovered ? Theme.cream : Theme.dim
                                font.pixelSize: 11 * root.s
                            }

                            HoverHandler { id: editBtnHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.focusIndex = brow.index;
                                    root.openEdit(brow.modelData);
                                }
                            }
                        }

                        // Delete Button
                        Rectangle {
                            visible: !brow.modelData.isMouse
                            width: 24 * root.s
                            height: 24 * root.s
                            radius: 5 * root.s
                            color: delBtnHover.hovered ? Qt.alpha(Theme.verm, 0.25) : Qt.alpha(Theme.cream, 0.045)
                            border.width: 1
                            border.color: delBtnHover.hovered ? Theme.vermLit : Theme.hairSoft
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delBtnHover.hovered ? Theme.vermLit : Theme.dim
                                font.pixelSize: 10.5 * root.s
                                font.weight: Font.Bold
                            }

                            HoverHandler { id: delBtnHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.formLine = brow.modelData.lineIndex;
                                    root.removeBind();
                                }
                            }
                        }
                    }

                    // Row click fallback to open edit
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 220 * root.s
                        enabled: !root.listening
                        cursorShape: brow.modelData.isMouse ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            root.focusIndex = brow.index;
                            root.openEdit(brow.modelData);
                        }
                    }
                }

                // Empty search state
                Item {
                    anchors.centerIn: parent
                    visible: root.filtered.length === 0
                    width: parent.width
                    height: 100 * root.s

                    Column {
                        anchors.centerIn: parent
                        spacing: 6 * root.s

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🔍 No matching keybinds found"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 13 * root.s
                            font.weight: Font.Medium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Try searching with a different term or clear the filter"
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                        }
                    }
                }
            }

            // Dedicated Wheel Scroller
            WheelScroller {
                anchors.fill: parent
                flick: list
                s: root.s
                z: -1
            }

            // Vertical Scroll Panel
            Item {
                id: scrollTrack
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 14 * root.s
                visible: listContainer.canScroll

                // Top Arrow Button
                Item {
                    id: topArrow
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: 12 * root.s

                    Text {
                        anchors.centerIn: parent
                        text: "▲"
                        color: topArrowHover.hovered ? Theme.cream : Theme.dim
                        font.pixelSize: 7.5 * root.s
                    }

                    HoverHandler { id: topArrowHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            list.contentY = Math.max(0, list.contentY - 120 * root.s);
                        }
                    }
                }

                // Bottom Arrow Button
                Item {
                    id: botArrow
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: 12 * root.s

                    Text {
                        anchors.centerIn: parent
                        text: "▼"
                        color: botArrowHover.hovered ? Theme.cream : Theme.dim
                        font.pixelSize: 7.5 * root.s
                    }

                    HoverHandler { id: botArrowHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            list.contentY = Math.min(listContainer.maxScroll, list.contentY + 120 * root.s);
                        }
                    }
                }

                // Track Body Area
                Item {
                    id: trackMid
                    anchors.top: topArrow.bottom
                    anchors.bottom: botArrow.top
                    anchors.topMargin: 2 * root.s
                    anchors.bottomMargin: 2 * root.s
                    anchors.left: parent.left
                    anchors.right: parent.right

                    // Subtle Track Rail
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2 * root.s
                        radius: 1 * root.s
                        color: Qt.alpha(Theme.cream, 0.08)
                    }

                    // Click track to jump directly
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => {
                            if (dragArea.drag.active) return;
                            var ratio = Math.max(0, Math.min(1, (m.y - thumb.height / 2) / (trackMid.height - thumb.height)));
                            list.contentY = ratio * listContainer.maxScroll;
                        }
                    }

                    // Draggable Rounded Thumb
                    Rectangle {
                        id: thumb
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: (dragArea.drag.active || thumbHover.hovered) ? 6 * root.s : 4 * root.s
                        height: Math.max(26 * root.s, Math.min(trackMid.height, (list.height / list.contentHeight) * trackMid.height))
                        radius: width / 2

                        // Reactive thumb position based on contentY
                        y: listContainer.maxScroll > 0
                            ? Math.max(0, Math.min(trackMid.height - height, (list.contentY / listContainer.maxScroll) * (trackMid.height - height)))
                            : 0

                        color: dragArea.drag.active ? Theme.vermLit
                             : (thumbHover.hovered ? Theme.cream : Qt.alpha(Theme.cream, 0.35))
                        border.width: dragArea.drag.active || thumbHover.hovered ? 1 : 0
                        border.color: Theme.hairSoft

                        Behavior on width { NumberAnimation { duration: Motion.fast } }
                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        HoverHandler { id: thumbHover }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            anchors.margins: -4 * root.s
                            cursorShape: Qt.PointingHandCursor
                            drag.target: thumb
                            drag.axis: Drag.YAxis
                            drag.minimumY: 0
                            drag.maximumY: trackMid.height - thumb.height

                            onPositionChanged: {
                                if (drag.active && trackMid.height > thumb.height) {
                                    var ratio = thumb.y / (trackMid.height - thumb.height);
                                    list.contentY = ratio * listContainer.maxScroll;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Form Drawer (Edit or Add mode)
        Column {
            id: form
            width: parent.width
            visible: root.formOpen
            spacing: 12 * root.s

            Item {
                width: parent.width
                height: 24 * root.s

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18 * root.s
                        height: 18 * root.s

                        GlyphIcon {
                            anchors.fill: parent
                            name: "chevron-left"
                            color: formBackArea.containsMouse ? Theme.cream : Theme.iconDim
                            stroke: 2.0
                        }

                        MouseArea {
                            id: formBackArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeForm()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.formAdd ? "ADD NEW KEYBIND" : "EDIT KEYBIND"
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                        font.weight: Font.Bold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.4 * root.s
                    }
                }
            }

            // Category Selection row in Form
            Item {
                width: parent.width
                height: 48 * root.s

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "CATEGORY"
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1 * root.s
                }

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30 * root.s
                    spacing: 6 * root.s

                    Repeater {
                        model: root.availableCategories
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool isSel: root.formCategory === modelData

                            height: 28 * root.s
                            width: fCatText.implicitWidth + 16 * root.s
                            radius: 6 * root.s
                            color: isSel ? Qt.alpha(Theme.vermLit, 0.22) : (fCatHover.hovered ? Qt.alpha(Theme.cream, 0.08) : Qt.alpha(Theme.cream, 0.045))
                            border.width: 1
                            border.color: isSel ? Theme.vermLit : (fCatHover.hovered ? Theme.subtle : Theme.hairSoft)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                id: fCatText
                                anchors.centerIn: parent
                                text: modelData
                                color: isSel ? Theme.vermLit : (fCatHover.hovered ? Theme.cream : Theme.dim)
                                font.family: Theme.font
                                font.pixelSize: 10.5 * root.s
                                font.weight: isSel ? Font.Bold : Font.Medium
                            }

                            HoverHandler { id: fCatHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.formCategory = modelData
                            }
                        }
                    }
                }
            }

            // Key Shortcut field
            Item {
                width: parent.width
                height: 48 * root.s

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "KEY SHORTCUT"
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1 * root.s
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 32 * root.s
                    radius: 7 * root.s
                    color: root.formRecording ? Qt.alpha(Theme.vermLit, 0.18) : Qt.alpha(Theme.cream, 0.045)
                    border.width: 1
                    border.color: root.formRecording ? Theme.vermLit : Theme.hairSoft

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.s
                        anchors.rightMargin: 8 * root.s
                        spacing: 8 * root.s

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.formRecording ? "●" : "⌨"
                            color: root.formRecording ? Theme.vermLit : Theme.dim
                            font.pixelSize: 11 * root.s
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 90 * root.s
                            text: root.formRecording ? "Press keys on your keyboard... (Esc cancels)"
                                : (root.formCombo.length ? root.comboPretty(root.formCombo) : "Click Rebind to capture shortcut")
                            color: root.formRecording ? Theme.vermLit
                                : (root.formCombo.length ? Theme.bright : Theme.faint)
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: root.formCombo.length ? Font.Bold : Font.Medium
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 68 * root.s
                            height: 24 * root.s
                            radius: 5 * root.s
                            color: root.formRecording ? Theme.vermLit : (rebindFormHover.hovered ? Qt.alpha(Theme.vermLit, 0.3) : Qt.alpha(Theme.cream, 0.08))
                            border.width: 1
                            border.color: root.formRecording ? Theme.vermLit : Theme.hairSoft

                            Text {
                                anchors.centerIn: parent
                                text: root.formRecording ? "Listening" : "Rebind"
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                                font.weight: Font.Medium
                            }

                            HoverHandler { id: rebindFormHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startFormRecording()
                            }
                        }
                    }
                }
            }

            // Name field
            Item {
                width: parent.width
                height: 48 * root.s

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "NAME / DESCRIPTION"
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1 * root.s
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 32 * root.s
                    radius: 7 * root.s
                    color: Qt.alpha(Theme.cream, 0.045)
                    border.width: 1
                    border.color: nameField.activeFocus ? Theme.vermLit : Theme.hairSoft

                    TextField {
                        id: nameField
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.s
                        anchors.rightMargin: 12 * root.s
                        background: null
                        padding: 0
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                        placeholderText: "e.g. Open Terminal, File Manager, Close Window"
                        placeholderTextColor: Theme.faint
                        selectByMouse: true
                        selectionColor: Theme.verm
                        text: root.formName
                        onTextEdited: root.formName = text
                        Keys.onPressed: (e) => {
                            if (e.key === Qt.Key_Escape) { root.closeForm(); e.accepted = true; }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.save(); e.accepted = true; }
                        }
                    }
                }
            }

            // Command field
            Item {
                width: parent.width
                height: 48 * root.s

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "COMMAND / ACTION"
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                    font.weight: Font.Bold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1 * root.s
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 32 * root.s
                    radius: 7 * root.s
                    color: Qt.alpha(Theme.cream, 0.045)
                    border.width: 1
                    border.color: cmdField.activeFocus ? Theme.vermLit : Theme.hairSoft

                    TextField {
                        id: cmdField
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.s
                        anchors.rightMargin: 12 * root.s
                        background: null
                        padding: 0
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        placeholderText: "e.g. ghostty, dolphin, hl.dsp.window.close()"
                        placeholderTextColor: Theme.faint
                        selectByMouse: true
                        selectionColor: Theme.verm
                        text: root.formCmd
                        onTextEdited: root.formCmd = text
                        Keys.onPressed: (e) => {
                            if (e.key === Qt.Key_Escape) { root.closeForm(); e.accepted = true; }
                            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.save(); e.accepted = true; }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.conflict.length > 0
                text: root.conflict
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // Form Action Buttons (Save, Delete, Cancel)
            Item {
                width: parent.width
                height: 34 * root.s

                Rectangle {
                    id: deleteBtn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.formAdd
                    width: deleteLabel.implicitWidth + 24 * root.s
                    height: 30 * root.s
                    radius: 7 * root.s
                    color: deleteArea.containsMouse ? Qt.alpha(Theme.verm, 0.3) : Qt.alpha(Theme.verm, 0.15)
                    border.width: 1
                    border.color: Qt.alpha(Theme.vermLit, 0.45)

                    Text {
                        id: deleteLabel
                        anchors.centerIn: parent
                        text: "Delete"
                        color: Theme.vermLit
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: deleteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeBind()
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    Rectangle {
                        width: cancelLabel.implicitWidth + 20 * root.s
                        height: 30 * root.s
                        radius: 7 * root.s
                        color: cancelArea.containsMouse ? Qt.alpha(Theme.cream, 0.1) : Qt.alpha(Theme.cream, 0.045)
                        border.width: 1
                        border.color: Theme.hairSoft

                        Text {
                            id: cancelLabel
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeForm()
                        }
                    }

                    Rectangle {
                        id: saveBtn
                        width: saveLabel.implicitWidth + 28 * root.s
                        height: 30 * root.s
                        radius: 7 * root.s
                        color: saveArea.containsMouse ? Theme.vermLit : Theme.verm

                        Text {
                            id: saveLabel
                            anchors.centerIn: parent
                            text: "Save"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: saveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.save()
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 8 * root.s }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hairSoft
        }

        Item {
            width: parent.width
            height: 22 * root.s

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 4 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 * root.s

                Text {
                    text: root.formOpen ? "SAVE · DELETE · ESC CANCEL" : "SUPER + /  ·  CLICK SHORTCUT TO REBIND  ·  ESC CLOSE"
                    color: Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1 * root.s
                }
            }
        }
    }

    // Floating Category Picker Popover (Overlay on top of everything)
    Item {
        id: categoryPickerOverlay
        anchors.fill: parent
        visible: root.categoryPickerData !== null
        z: 999

        // Dismiss background click
        MouseArea {
            anchors.fill: parent
            onClicked: root.categoryPickerData = null
        }

        Rectangle {
            id: categoryPickerMenu
            x: root.categoryPickerData ? root.categoryPickerData.x : 0
            y: root.categoryPickerData ? root.categoryPickerData.y : 0
            width: 120 * root.s
            height: catPickerCol.implicitHeight + 10 * root.s
            radius: 8 * root.s
            color: Theme.cardTop
            border.width: 1
            border.color: Theme.vermLit

            Column {
                id: catPickerCol
                anchors.top: parent.top
                anchors.topMargin: 5 * root.s
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2 * root.s

                Repeater {
                    model: root.availableCategories
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool isSelected: root.categoryPickerData && root.categoryPickerData.currentCat === modelData

                        width: catPickerCol.width - 8 * root.s
                        height: 26 * root.s
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 5 * root.s
                        color: isSelected ? Qt.alpha(Theme.vermLit, 0.25)
                             : (itemHover.hovered ? Qt.alpha(Theme.cream, 0.08) : "transparent")
                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: isSelected ? Theme.vermLit : (itemHover.hovered ? Theme.bright : Theme.cream)
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: isSelected ? Font.Bold : Font.Medium
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            visible: isSelected
                            text: "✓"
                            color: Theme.vermLit
                            font.pixelSize: 10 * root.s
                            font.weight: Font.Bold
                        }

                        HoverHandler { id: itemHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.categoryPickerData) {
                                    root.setCategoryForBind(root.categoryPickerData.lineIndex, modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

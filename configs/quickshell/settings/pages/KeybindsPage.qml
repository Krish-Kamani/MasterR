import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Item {
    id: root

    property var allBinds: []
    property string activeCategory: "All"
    property string filterQuery: ""

    // Modal Dialog State
    property bool modalVisible: false
    property bool isEditing: false
    property int editingLine: -1
    property string modalKey: ""
    property string modalCommand: ""
    property string modalCategory: "Custom"
    property string modalDescription: ""

    // Shell runner process for add/edit/remove
    Process {
        id: cmdProc
        command: ["true"]
        onExited: {
            listBindsProc.running = true;
        }
    }

    // Process to list all keybindings using StdioCollector
    Process {
        id: listBindsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds-manager.py", "--list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allBinds = JSON.parse(this.text);
                } catch (e) {
                    root.allBinds = [];
                }
            }
        }
    }

    readonly property var filteredBinds: {
        var res = root.allBinds;
        if (root.activeCategory !== "All") {
            res = res.filter(b => b.category.toLowerCase() === root.activeCategory.toLowerCase());
        }
        if (root.filterQuery && root.filterQuery.trim().length > 0) {
            var q = root.filterQuery.toLowerCase().trim();
            res = res.filter(b => b.key.toLowerCase().includes(q) || b.description.toLowerCase().includes(q) || (b.command && b.command.toLowerCase().includes(q)) || (b.action && b.action.toLowerCase().includes(q)));
        }
        return res;
    }

    function openAddModal() {
        root.isEditing = false;
        root.editingLine = -1;
        root.modalKey = "SUPER + ";
        root.modalCommand = "";
        root.modalCategory = root.activeCategory !== "All" ? root.activeCategory : "Custom";
        root.modalDescription = "";
        root.modalVisible = true;
    }

    function openEditModal(bindItem) {
        root.isEditing = true;
        root.editingLine = bindItem.line;
        root.modalKey = bindItem.key;
        root.modalCommand = bindItem.command || bindItem.action;
        root.modalCategory = bindItem.category || "Custom";
        root.modalDescription = bindItem.description || "";
        root.modalVisible = true;
    }

    function saveModal() {
        if (!root.modalKey || root.modalKey.trim().length === 0) return;
        if (!root.modalCommand || root.modalCommand.trim().length === 0) return;

        var script = Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds-manager.py";
        if (root.isEditing) {
            cmdProc.command = [
                "python3", script, "--edit",
                root.editingLine.toString(),
                root.modalKey.trim(),
                root.modalCommand.trim(),
                root.modalCategory.trim(),
                root.modalDescription.trim()
            ];
        } else {
            cmdProc.command = [
                "python3", script, "--add",
                root.modalKey.trim(),
                root.modalCommand.trim(),
                root.modalCategory.trim(),
                root.modalDescription.trim()
            ];
        }
        cmdProc.running = true;
        root.modalVisible = false;
    }

    function deleteBind(lineNum) {
        var script = Quickshell.env("HOME") + "/.config/hypr/scripts/keybinds-manager.py";
        cmdProc.command = ["python3", script, "--remove", lineNum.toString()];
        cmdProc.running = true;
    }

    Flickable {
        id: scrollArea
        anchors.fill: parent
        contentHeight: contentCol.implicitHeight + 60
        clip: true

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 20

            PageHeader {
                glyph: "鍵"
                title: "Keybindings & Hotkeys"
                subtitle: "Browse, search, add, edit, and remove Hyprland keyboard shortcuts and application launch triggers."
                badgeText: "BINDS.LUA"
            }

            // Toolbar & Action Card
            Card {
                title: "Shortcut Controls & Search"
                subtitle: "Search hotkeys, filter by subsystem category, or create new custom keybindings"
                icon: "search"

                Row {
                    width: parent.width
                    spacing: 12

                    SearchBar {
                        width: parent.width - 180
                        placeholder: "Search by key (e.g. Return, Space, B) or action (e.g. Terminal, Zen, Fullscreen)..."
                        onSearchChanged: (q) => root.filterQuery = q
                    }

                    Button {
                        width: 168
                        text: "+ Add Shortcut"
                        icon: "plus"
                        variant: "primary"
                        onClicked: root.openAddModal()
                    }
                }

                SegmentedBar {
                    model: ["All", "Apps", "Window", "Workspaces", "Launchers", "Media", "Custom"]
                    currentIndex: 0
                    onSelected: (idx, val) => root.activeCategory = val
                }
            }

            // Keybindings Table Card
            Card {
                title: "Configured Shortcuts (" + root.filteredBinds.length + " keybinds)"
                subtitle: "Defined in ~/.config/hypr/modules/binds.lua — edits reload Hyprland immediately"
                icon: "keyboard"

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.filteredBinds

                        Rectangle {
                            id: bindRow
                            width: parent.width
                            height: 64
                            radius: 12
                            color: rowMouse.containsMouse ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.08) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.20)
                            border.color: rowMouse.containsMouse ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                // Key combo representation
                                Row {
                                    id: keysRow
                                    width: 230
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    readonly property var tokens: {
                                        var parts = modelData.key.split("+");
                                        var res = [];
                                        for (var i = 0; i < parts.length; i++) {
                                            var tok = parts[i].trim();
                                            if (tok.length > 0) res.push(tok);
                                        }
                                        return res;
                                    }

                                    Repeater {
                                        model: keysRow.tokens

                                        Row {
                                            spacing: 4
                                            anchors.verticalCenter: parent.verticalCenter

                                            // 3D Glass Keyboard Cap
                                            Rectangle {
                                                height: 26
                                                width: keyCapText.implicitWidth + 14
                                                radius: 6
                                                color: Qt.rgba(0, 0, 0, 0.65)
                                                border.color: Qt.rgba(255, 255, 255, 0.22)
                                                border.width: 1

                                                // Top Bevel
                                                Rectangle {
                                                    anchors.top: parent.top
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    height: 1
                                                    color: Qt.rgba(255, 255, 255, 0.3)
                                                }

                                                Text {
                                                    id: keyCapText
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    color: Theme.bright
                                                }
                                            }

                                            Text {
                                                visible: index < keysRow.tokens.length - 1
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "+"
                                                font.family: Theme.fontUI
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: Theme.faint
                                            }
                                        }
                                    }
                                }

                                // Middle description and command
                                Column {
                                    width: parent.width - 230 - 120 - 48
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Row {
                                        spacing: 8

                                        Text {
                                            text: modelData.description || modelData.key
                                            font.family: Theme.fontUI
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            color: Theme.bright
                                        }

                                        Rectangle {
                                            height: 18
                                            width: catBadgeText.implicitWidth + 10
                                            radius: 4
                                            color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.18)
                                            border.color: Theme.onGlow
                                            border.width: 1

                                            Text {
                                                id: catBadgeText
                                                anchors.centerIn: parent
                                                text: modelData.category
                                                font.family: Theme.fontUI
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: Theme.onGlow
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: modelData.command || modelData.action
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: Theme.dim
                                        elide: Text.ElideMiddle
                                    }
                                }

                                // Action Buttons (Edit & Delete)
                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    // Edit Button
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: editMouse.containsMouse ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.25) : Qt.rgba(255, 255, 255, 0.06)
                                        border.color: editMouse.containsMouse ? Theme.onGlow : Qt.rgba(255, 255, 255, 0.12)
                                        border.width: 1

                                        GlyphIcon {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            name: "edit"
                                            color: editMouse.containsMouse ? Theme.onGlow : Theme.iconDim
                                            stroke: 1.8
                                        }

                                        MouseArea {
                                            id: editMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openEditModal(modelData)
                                        }
                                    }

                                    // Delete Button
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: delMouse.containsMouse ? Qt.rgba(216, 56, 32, 0.3) : Qt.rgba(255, 255, 255, 0.06)
                                        border.color: delMouse.containsMouse ? "#ef4444" : Qt.rgba(255, 255, 255, 0.12)
                                        border.width: 1

                                        GlyphIcon {
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14
                                            name: "trash"
                                            color: delMouse.containsMouse ? "#ef4444" : Theme.iconDim
                                            stroke: 1.8
                                        }

                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deleteBind(modelData.line)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }

    // Modal Dialog Overlay for Add / Edit Keybinding
    Rectangle {
        id: modalOverlay
        anchors.fill: parent
        z: 100
        visible: root.modalVisible
        color: Qt.rgba(0, 0, 0, 0.76)

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            id: dialogCard
            anchors.centerIn: parent
            width: 530
            implicitHeight: dialogCol.implicitHeight + 40
            radius: 18
            color: Qt.rgba(Theme.tileBg.r, Theme.tileBg.g, Theme.tileBg.b, 0.96)
            border.color: Theme.onGlow
            border.width: 1.5

            scale: root.modalVisible ? 1.0 : 0.95
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

            // Specular top highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(255, 255, 255, 0.3)
            }

            Column {
                id: dialogCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 22
                spacing: 16

                // Header
                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 10
                        color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.2)
                        border.color: Theme.onGlow
                        border.width: 1

                        GlyphIcon {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            name: "keyboard"
                            color: Theme.onGlow
                            stroke: 2.0
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.isEditing ? "Edit Keybinding" : "Add New Keybinding"
                            font.family: Theme.fontUI
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: Theme.bright
                        }

                        Text {
                            text: root.isEditing ? "Modifying bind on line " + root.editingLine + " of binds.lua" : "Defines a new shortcut in ~/.config/hypr/modules/binds.lua"
                            font.family: Theme.fontUI
                            font.pixelSize: 11
                            color: Theme.dim
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.hair }

                // Key Combination Input
                InputField {
                    width: parent.width
                    label: "Key Combination"
                    placeholder: "e.g. SUPER + Shift + T or Alt + Space"
                    text: root.modalKey
                    isMonospace: true
                    onTextChanged: root.modalKey = text
                }

                // Command / Action Input
                InputField {
                    width: parent.width
                    label: "Command to Execute"
                    placeholder: "e.g. ghostty or firefox or hl.dsp.window.close()"
                    text: root.modalCommand
                    isMonospace: true
                    onTextChanged: root.modalCommand = text
                }

                // Category Selector
                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        text: "Category"
                        font.family: Theme.fontUI
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.bright
                    }

                    SegmentedBar {
                        model: ["Apps", "Window", "Workspaces", "Launchers", "Media", "Custom"]
                        currentIndex: {
                            var cats = ["Apps", "Window", "Workspaces", "Launchers", "Media", "Custom"];
                            var idx = cats.indexOf(root.modalCategory);
                            return idx >= 0 ? idx : 5;
                        }
                        onSelected: (idx, val) => root.modalCategory = val
                    }
                }

                // Description Input
                InputField {
                    width: parent.width
                    label: "Shortcut Description"
                    placeholder: "e.g. Launch Terminal or Close Window"
                    text: root.modalDescription
                    onTextChanged: root.modalDescription = text
                }

                Rectangle { width: parent.width; height: 1; color: Theme.hair }

                // Dialog Buttons
                Row {
                    anchors.right: parent.right
                    spacing: 12

                    Button {
                        text: "Cancel"
                        variant: "secondary"
                        onClicked: root.modalVisible = false
                    }

                    Button {
                        text: root.isEditing ? "Save Changes" : "Add Shortcut"
                        icon: "check"
                        variant: "primary"
                        onClicked: root.saveModal()
                    }
                }
            }
        }
    }
}

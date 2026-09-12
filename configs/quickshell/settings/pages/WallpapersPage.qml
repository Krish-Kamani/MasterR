import QtQuick
import Quickshell
import Quickshell.Io
import "../Singletons"
import "../components"

Flickable {
    id: root

    contentHeight: contentCol.implicitHeight + 60
    clip: true

    property var allWallpapers: []
    property string currentWallpaper: ""
    property string activeFilter: "all" // "all", "video", "still"
    property string searchQuery: ""
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/masterr-wp-thumbs/"

    Process {
        id: cmdProc
        command: ["true"]
    }

    // Read current wallpaper state
    Process {
        id: stateProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "_", (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/masterr-wallpaper"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0) {
                    root.currentWallpaper = this.text.trim();
                }
            }
        }
    }

    // List wallpapers process using StdioCollector
    Process {
        id: listWallpapersProc
        command: [
            "sh", "-c",
            "WP_DIR=\"$1\"; if [ ! -d \"$WP_DIR\" ]; then WP_DIR=\"$HOME/Pictures/Wallpapers\"; fi; find \"$WP_DIR\" -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) -printf '%T@\\t%p\\n' | sort -rn",
            "_",
            Flags.wallpaperDir && Flags.wallpaperDir.length > 0 ? Flags.wallpaperDir : (Quickshell.env("HOME") + "/Pictures/Wallpapers")
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    var tab = line.indexOf("\t");
                    var p = tab >= 0 ? line.substring(tab + 1) : line;
                    var name = p.substring(p.lastIndexOf("/") + 1);
                    var isVid = /\.(mp4|webm|mkv|mov)$/i.test(p);
                    list.push({
                        path: p,
                        name: name,
                        thumb: root.thumbDir + name + ".png",
                        isVideo: isVid
                    });
                }
                root.allWallpapers = list;
                stateProc.running = true;
            }
        }
    }

    function applyWallpaper(path) {
        root.currentWallpaper = path;
        var script = Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper.sh";
        if (Flags.randomScope === "cursor") {
            cmdProc.command = ["bash", script, "set", path, "focused"];
        } else {
            cmdProc.command = ["bash", script, "set", path];
        }
        cmdProc.running = true;
    }

    readonly property var filteredWallpapers: {
        var res = root.allWallpapers;
        if (root.activeFilter === "video") {
            res = res.filter(w => w.isVideo);
        } else if (root.activeFilter === "still") {
            res = res.filter(w => !w.isVideo);
        }
        if (root.searchQuery && root.searchQuery.trim().length > 0) {
            var q = root.searchQuery.toLowerCase().trim();
            res = res.filter(w => w.name.toLowerCase().includes(q));
        }
        return res;
    }

    readonly property var currentWpObj: {
        for (var i = 0; i < root.allWallpapers.length; i++) {
            if (root.allWallpapers[i].path === root.currentWallpaper) {
                return root.allWallpapers[i];
            }
        }
        if (root.currentWallpaper.length > 0) {
            var n = root.currentWallpaper.substring(root.currentWallpaper.lastIndexOf("/") + 1);
            return {
                path: root.currentWallpaper,
                name: n,
                thumb: root.thumbDir + n + ".png",
                isVideo: /\.(mp4|webm|mkv|mov)$/i.test(root.currentWallpaper)
            };
        }
        return null;
    }

    Column {
        id: contentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        PageHeader {
            glyph: "壁"
            title: "Wallpapers & Live Video"
            subtitle: "Browse 4K stills and animated live MP4 video wallpapers with dynamic palette regeneration."
            badgeText: "MATUGEN SYNC"
        }

        // Active Wallpaper Hero Showcase Card
        Rectangle {
            width: parent.width
            height: 130
            radius: 16
            color: Qt.rgba(Theme.cardBot.r, Theme.cardBot.g, Theme.cardBot.b, 0.72)
            border.color: Theme.onGlow
            border.width: 1.5
            clip: true

            // Specular top highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                height: 1
                color: Qt.rgba(255, 255, 255, 0.25)
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 18

                // Thumbnail preview
                Rectangle {
                    width: 176
                    height: parent.height
                    radius: 10
                    color: Theme.tileBg
                    clip: true
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        source: root.currentWpObj ? ("file://" + (root.currentWpObj.isVideo ? root.currentWpObj.thumb : root.currentWpObj.path)) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 400
                        sourceSize.height: 250
                    }

                    // Live badge
                    Rectangle {
                        visible: root.currentWpObj ? root.currentWpObj.isVideo : false
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 6
                        height: 18
                        radius: 4
                        color: Qt.rgba(0, 0, 0, 0.75)
                        border.color: Theme.onGlow
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            anchors.margins: 4
                            spacing: 4
                            Text {
                                text: "▶ LIVE"
                                font.family: Theme.fontUI
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                color: Theme.onGlow
                            }
                        }
                    }
                }

                // Info column
                Column {
                    width: parent.width - 194 - 170
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Row {
                        spacing: 8
                        Rectangle {
                            height: 20
                            width: activeBadgeText.implicitWidth + 12
                            radius: 10
                            color: Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.2)
                            border.color: Theme.onGlow
                            border.width: 1

                            Text {
                                id: activeBadgeText
                                anchors.centerIn: parent
                                text: "CURRENTLY ACTIVE"
                                font.family: Theme.fontUI
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.onGlow
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.currentWpObj && root.currentWpObj.isVideo ? "Animated Video (awww loop)" : "Static 4K Image"
                            font.family: Theme.fontUI
                            font.pixelSize: 11
                            color: Theme.dim
                        }
                    }

                    Text {
                        width: parent.width
                        text: root.currentWpObj ? root.currentWpObj.name : "Detecting active wallpaper..."
                        font.family: Theme.fontUI
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.bright
                        elide: Text.ElideMiddle
                    }

                    Text {
                        width: parent.width
                        text: root.currentWallpaper || "No active wallpaper path"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.faint
                        elide: Text.ElideMiddle
                    }
                }

                // Quick buttons
                Column {
                    width: 160
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Button {
                        width: parent.width
                        text: "Shuffle Random"
                        icon: "sparkles"
                        variant: "primary"
                        onClicked: {
                            var script = Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper.sh";
                            cmdProc.command = ["bash", script, "random"];
                            cmdProc.running = true;
                            Qt.callLater(() => stateProc.running = true);
                        }
                    }

                    Button {
                        width: parent.width
                        text: "Open Folder"
                        icon: "folder"
                        variant: "secondary"
                        onClicked: {
                            var dir = Flags.wallpaperDir && Flags.wallpaperDir.length > 0 ? Flags.wallpaperDir : (Quickshell.env("HOME") + "/Pictures/Wallpapers");
                            cmdProc.command = ["xdg-open", dir];
                            cmdProc.running = true;
                        }
                    }
                }
            }
        }

        // Filtering & Targeting Card
        Card {
            title: "Filter & Target Settings"
            subtitle: "Search collection, filter by media format, and configure multi-monitor targeting"
            icon: "settings"

            Row {
                width: parent.width
                spacing: 12

                SearchBar {
                    width: parent.width - 250
                    placeholder: "Search wallpapers (" + root.filteredWallpapers.length + " matching)..."
                    onSearchChanged: (q) => root.searchQuery = q
                }

                SegmentedBar {
                    width: 238
                    model: [
                        { label: "All (" + root.allWallpapers.length + ")", value: "all" },
                        { label: "Videos", value: "video" },
                        { label: "Stills", value: "still" }
                    ]
                    currentIndex: root.activeFilter === "all" ? 0 : (root.activeFilter === "video" ? 1 : 2)
                    onSelected: (idx, val) => root.activeFilter = val
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.hair }

            Row {
                width: parent.width
                spacing: 16

                Item {
                    width: parent.width - 180
                    height: segTarget.implicitHeight

                    SegmentedBar {
                        id: segTarget
                        anchors.fill: parent
                        label: "Random Wallpaper Targeting Scope"
                        model: [
                            { label: "🖥️ All Monitors Simultaneously", value: "all" },
                            { label: "🎯 Focused / Cursor Monitor Only", value: "cursor" }
                        ]
                        currentIndex: Flags.randomScope === "cursor" ? 1 : 0
                        onSelected: (idx, val) => Flags.randomScope = val
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Re-scan Library"
                    icon: "rotate-ccw"
                    variant: "secondary"
                    onClicked: {
                        listWallpapersProc.running = true;
                    }
                }
            }
        }

        // Wallpaper Grid Card
        Card {
            title: "Wallpaper Library (" + root.filteredWallpapers.length + " wallpapers)"
            subtitle: "Click any wallpaper to apply immediately across your desktop with synchronized re-theming"
            icon: "grid"

            Grid {
                width: parent.width
                columns: 3
                spacing: 14

                Repeater {
                    model: root.filteredWallpapers

                    Rectangle {
                        id: wpCard
                        width: (parent.width - 28) / 3
                        height: 144
                        radius: 12
                        color: Theme.tileBg
                        readonly property bool isActive: root.currentWallpaper === modelData.path
                        border.color: isActive ? Theme.onGlow : (itemMouse.containsMouse ? Qt.rgba(Theme.onGlow.r, Theme.onGlow.g, Theme.onGlow.b, 0.7) : Qt.rgba(255, 255, 255, 0.09))
                        border.width: isActive ? 2 : 1
                        clip: true

                        scale: itemMouse.containsMouse ? 1.025 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Background image preview
                        Image {
                            anchors.fill: parent
                            source: "file://" + (modelData.isVideo ? modelData.thumb : modelData.path)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 320
                            sourceSize.height: 180
                            opacity: itemMouse.containsMouse || wpCard.isActive ? 1.0 : 0.88

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Top Gradient scrim
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.65) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        // Live Video Badge
                        Rectangle {
                            visible: modelData.isVideo
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 8
                            height: 20
                            width: liveText.implicitWidth + 14
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.75)
                            border.color: Theme.onGlow
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                GlyphIcon {
                                    width: 10
                                    height: 10
                                    name: "video"
                                    color: Theme.onGlow
                                    stroke: 2.0
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    id: liveText
                                    text: "LIVE"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.onGlow
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Active Indicator Badge
                        Rectangle {
                            visible: wpCard.isActive
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            height: 22
                            width: activeCheckText.implicitWidth + 16
                            radius: 11
                            color: Theme.onGlow
                            border.color: "#ffffff"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "✓"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.tileBg
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    id: activeCheckText
                                    text: "ACTIVE"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.tileBg
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        // Bottom Title Bar scrim
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 38
                            color: Qt.rgba(0, 0, 0, 0.72)

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Qt.rgba(255, 255, 255, 0.14)
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    text: modelData.name
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: wpCard.isActive ? Theme.onGlow : "#ffffff"
                                    elide: Text.ElideMiddle
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.applyWallpaper(modelData.path);
                            }
                        }
                    }
                }
            }
        }
    }
}

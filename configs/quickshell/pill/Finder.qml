pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"

/**
 * Finder surface: fast file & folder search panel for the MasterR pill.
 * Features fuzzy/substring search over $HOME, Ame glowing caret tracking,
 * and launches folders or containing folders in the default file manager.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 11
    mRight: 11
    mBottom: 14

    property string query: ""
    property int selectedIndex: 0
    property var results: []

    readonly property string searchScript: Quickshell.env("HOME") + "/.config/hypr/scripts/find-files.py"
    readonly property string openScript: Quickshell.env("HOME") + "/.config/hypr/scripts/open-file-target.sh"

    /**
     * Window-coordinate position of the last hover event that was allowed to
     * move the selection. Rows sliding under a stationary cursor during
     * keyboard scrolling produce hover events at an unchanged window position,
     * which must not steal the keyboard selection.
     */
    property point lastPointer: Qt.point(-1, -1)

    readonly property point caretPoint: {
        void root.width;
        void root.height;
        void search.input.width;
        return search.input.mapToItem(root,
            search.input.cursorRectangle.x + search.input.cursorRectangle.width / 2,
            search.input.cursorRectangle.y + search.input.cursorRectangle.height / 2);
    }
    readonly property real caretX: caretPoint.x
    readonly property real caretY: caretPoint.y

    ameForm: "caret"
    amePoint: Qt.point(caretX, caretY)

    function focusField() { search.input.forceActiveFocus(); }

    function move(delta) {
        if (results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function activate() {
        if (results.length === 0 || selectedIndex < 0 || selectedIndex >= results.length)
            return;
        var entry = results[selectedIndex];
        if (entry && entry.path) {
            Quickshell.execDetached(["bash", root.openScript, entry.path, entry.isDir ? "dir" : "file"]);
        }
        root.requestClose();
    }

    function runSearch() {
        if (searchProc.running)
            searchProc.running = false;
        searchProc.command = [root.searchScript, root.query];
        searchProc.running = true;
    }

    Timer {
        id: debounceTimer
        interval: 50
        repeat: false
        onTriggered: root.runSearch()
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text);
                    root.results = parsed || [];
                } catch (e) {
                    root.results = [];
                }
            }
        }
    }

    function fileIconName(ext) {
        if (!ext || ext.length === 0)
            return "text-plain";
        var e = ext.toLowerCase();
        if (e === "png" || e === "jpg" || e === "jpeg" || e === "gif" || e === "webp" || e === "svg" || e === "ico")
            return "image-x-generic";
        if (e === "mp3" || e === "flac" || e === "wav" || e === "ogg" || e === "m4a" || e === "opus" || e === "aac")
            return "audio-x-generic";
        if (e === "mp4" || e === "mkv" || e === "webm" || e === "avi" || e === "mov" || e === "flv")
            return "video-x-generic";
        if (e === "pdf")
            return "application-pdf";
        if (e === "zip" || e === "tar" || e === "gz" || e === "xz" || e === "7z" || e === "rar" || e === "bz2")
            return "package-x-generic";
        if (e === "js" || e === "ts" || e === "py" || e === "sh" || e === "lua" || e === "qml" || e === "cpp" || e === "c" || e === "rs" || e === "go" || e === "html" || e === "css" || e === "json")
            return "text-x-script";
        if (e === "md" || e === "txt" || e === "doc" || e === "docx")
            return "text-plain";
        return "text-plain";
    }

    onActiveChanged: {
        if (active) {
            query = "";
            search.text = "";
            selectedIndex = 0;
            results = [];
            runSearch();
            Qt.callLater(root.focusField);
        }
    }

    onResultsChanged: {
        if (selectedIndex >= results.length)
            selectedIndex = 0;
    }

    SearchField {
        id: search
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        kanji: "索"
        placeholder: "Search files & folders"
        counterText: root.results.length + (root.results.length === 1 ? " result" : " results")
        onTextChanged: {
            root.query = text;
            root.selectedIndex = 0;
            debounceTimer.restart();
        }
        onMoved: (d) => root.move(d)
        onAccepted: root.activate()
        onDismissed: root.requestClose()
    }

    Rectangle {
        id: divider
        anchors.top: search.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    Text {
        anchors.centerIn: list
        visible: root.results.length === 0 && !searchProc.running
        text: root.query.length ? "No matching files or folders" : "Type to search..."
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    ListView {
        id: list
        anchors.top: divider.bottom
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 5 * root.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results.length

        delegate: Item {
            id: fileRow
            required property int index
            width: list.width
            height: 38 * root.s

            readonly property var entry: root.results[index]
            readonly property bool selected: index === root.selectedIndex
            readonly property bool isDir: entry ? !!entry.isDir : false

            Rectangle {
                anchors.fill: parent
                radius: 9 * root.s
                visible: fileRow.selected || rowArea.containsMouse
                color: fileRow.selected ? Theme.frameBg : Qt.rgba(0.94, 0.88, 0.84, 0.03)
                border.width: fileRow.selected ? 1 : 0
                border.color: Theme.frameBorder
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: (m) => {
                    var g = rowArea.mapToItem(null, m.x, m.y);
                    if (g.x !== root.lastPointer.x || g.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(g.x, g.y);
                        root.selectedIndex = fileRow.index;
                    }
                }
                onClicked: {
                    root.selectedIndex = fileRow.index;
                    root.activate();
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 11 * root.s
                anchors.rightMargin: 11 * root.s

                Rectangle {
                    id: iconBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: fileRow.isDir ? Qt.rgba(0.88, 0.45, 0.25, 0.12) : Qt.rgba(1, 1, 1, 0.05)

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 14 * root.s
                        height: 14 * root.s
                        name: fileRow.isDir ? "folder" : "file-text"
                        color: fileRow.isDir ? Theme.vermLit : (fileRow.selected ? Theme.cream : Theme.dim)
                        stroke: 1.8
                        visible: !(mimeIcon.status === Image.Ready && mimeIcon.source != "")
                    }

                    Image {
                        id: mimeIcon
                        anchors.centerIn: parent
                        width: 16 * root.s
                        height: 16 * root.s
                        sourceSize.width: Math.round(32 * root.s)
                        sourceSize.height: Math.round(32 * root.s)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        visible: status === Image.Ready && source != ""
                        source: {
                            if (!fileRow.entry)
                                return "";
                            if (fileRow.isDir) {
                                var pDir = Quickshell.iconPath("folder", true);
                                return pDir || "";
                            }
                            var icName = root.fileIconName(fileRow.entry.ext);
                            var p = Quickshell.iconPath(icName, true);
                            return (p && p.length > 0) ? p : "";
                        }
                    }
                }

                TextMetrics {
                    id: retMetrics
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    text: "↵"
                }
                Text {
                    id: ret
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    text: retMetrics.text
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    visible: fileRow.selected
                    width: visible ? retMetrics.advanceWidth + 6 * root.s : 0
                    horizontalAlignment: Text.AlignRight
                }

                Column {
                    anchors.left: iconBg.right
                    anchors.leftMargin: 10 * root.s
                    anchors.right: ret.left
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1 * root.s

                    Row {
                        width: parent.width
                        spacing: 6 * root.s

                        Text {
                            id: nameText
                            text: fileRow.entry ? fileRow.entry.name : ""
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 13 * root.s
                            font.weight: fileRow.selected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            width: Math.min(implicitWidth, parent.width - (typeBadge.visible ? typeBadge.width + 6 * root.s : 0))
                        }

                        Rectangle {
                            id: typeBadge
                            anchors.verticalCenter: parent.verticalCenter
                            visible: fileRow.isDir || (fileRow.entry && fileRow.entry.ext && fileRow.entry.ext.length > 0)
                            width: badgeText.implicitWidth + 8 * root.s
                            height: 14 * root.s
                            radius: 3 * root.s
                            color: fileRow.isDir ? Qt.rgba(0.88, 0.45, 0.25, 0.15) : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: fileRow.isDir ? "DIR" : (fileRow.entry ? fileRow.entry.ext.toUpperCase() : "")
                                color: fileRow.isDir ? Theme.vermLit : Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 8.5 * root.s
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Text {
                        id: pathText
                        width: parent.width
                        text: fileRow.entry ? fileRow.entry.parent : ""
                        color: fileRow.selected ? Theme.dim : Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }

    WheelScroller {
        anchors.fill: list
        s: root.s
        flick: list
    }
}

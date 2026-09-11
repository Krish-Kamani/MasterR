import QtQuick
import Quickshell
import Quickshell.Io
import "Singletons"

ShellRoot {
    id: root

    IpcHandler {
        target: "settings"
        function showCategory(cat: string): void {
            console.log("IPC showCategory called with cat:", cat);
            if (cat && cat.length > 0) {
                Nav.currentCategory = cat;
            }
            win.visible = true;
        }
        function close(): void {
            win.visible = false;
        }
    }

    FloatingWindow {
        id: win
        title: "MasterR Settings"
        implicitWidth: 1140
        implicitHeight: 760
        visible: true
        color: "transparent"

        SettingsApp {
            id: settingsApp
            anchors.fill: parent
            onCloseRequested: Qt.quit()
        }

        Shortcut {
            sequence: "Escape"
            onActivated: Qt.quit()
        }
    }
}

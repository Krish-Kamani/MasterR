pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Wallpaper-derived palette, same matugen JSON the pill watches, trimmed to
 * the tokens the lock consumes. Never source anything from on_primary_container:
 * matugen can leave it empty through JsonAdapter and the token collapses to
 * black (the pill learned this the hard way).
 */
Singleton {
    readonly property string primary: adapter.primary
    readonly property string cream: adapter.cream
    readonly property string bright: adapter.bright
    readonly property string dim: adapter.dim

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/masterr/colors.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string primary: "#f5bd6f"
            property string cream: "#e6d6cb"
            property string bright: "#fff6f0"
            property string dim: "#8a7d74"
        }
    }
}

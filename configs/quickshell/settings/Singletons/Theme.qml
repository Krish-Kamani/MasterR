pragma Singleton
import QtQuick
import Quickshell

/**
 * Liquid Glass Palette & Design Tokens for MasterR Settings.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode !== "static"

    readonly property color onGlow: dyn ? Dyn.primary : "#ff9a64"
    readonly property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : "#c0442b"
    readonly property color vermLit:  dyn ? Dyn.primary : "#e0563b"
    readonly property color vermDeep: dyn ? Dyn.primaryContainer : "#a3371f"
    readonly property color cream:    dyn ? Dyn.cream : "#e6d6cb"
    readonly property color bright:   dyn ? Dyn.bright : "#fff6f0"
    readonly property color dim:      dyn ? Dyn.dim : "#8a7d74"
    readonly property color cardTop:  dyn ? Dyn.surfaceContainerHigh : "#2e231b"
    readonly property color cardBot:  dyn ? Dyn.surfaceContainerLow : "#221813"
    readonly property color border:   dyn ? Dyn.outlineVariant : "#3a2a22"
    readonly property color shadow:   Qt.rgba(0, 0, 0, 0.55)
    readonly property color tileBg:   dyn ? Dyn.surface : "#211711"
    readonly property color subtle:   dyn ? Dyn.subtle : "#b9a99e"
    readonly property color faint:    dyn ? Dyn.faint : "#6f635b"
    readonly property color iconDim:  dyn ? Dyn.iconDim : "#cdbfb4"
    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    Qt.alpha(cream, 0.07)
    readonly property color frameBg:  Qt.alpha(cream, 0.055)
    readonly property color frameBorder: Qt.alpha(cream, 0.10)
    readonly property color flameCore: dyn ? Qt.lighter(onGlow, 1.03) : "#ffd9c2"

    // Standardized typography tokens
    readonly property string fontUI: "Inter"
    readonly property string fontDisplay: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontJp: "Zen Kaku Gothic New"
    readonly property string font: "Inter"
}

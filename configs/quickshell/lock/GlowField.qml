pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

Item {
    id: glow
    property color accent: Theme.verm

    readonly property bool live: Cava.active && !Cava.quiet
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    opacity: live ? 0.74 : 0
    visible: opacity > 0.004

    Behavior on opacity {
        NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad }
    }

    onVisibleChanged: {
        if (!visible)
            levels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    }

    FrameAnimation {
        running: glow.visible
        onTriggered: {
            var src = Cava.values;
            var dt = Math.min(frameTime, 0.05);
            var next = [];
            for (var i = 0; i < Cava.bars; i++) {
                var cur = glow.levels[i] !== undefined ? glow.levels[i] : 0;
                /** 1.6 gain so quiet tracks still read as a glow, clamped so loud ones never blow out. */
                var target = Math.min(1, (src && src[i] !== undefined ? src[i] : 0) * 1.6);
                var tau = target > cur ? 0.18 : 1.1;
                var k = 1 - Math.exp(-dt / tau);
                next.push(cur + (target - cur) * k);
            }
            glow.levels = next;
        }
    }

    ShaderEffect {
        anchors.fill: parent
        property color accent: glow.accent
        property vector4d band0: Qt.vector4d(glow.levels[0], glow.levels[1], glow.levels[2], glow.levels[3])
        property vector4d band1: Qt.vector4d(glow.levels[4], glow.levels[5], glow.levels[6], glow.levels[7])
        property vector4d band2: Qt.vector4d(glow.levels[8], glow.levels[9], glow.levels[10], glow.levels[11])
        fragmentShader: "shaders/glow.frag.qsb"
    }
}

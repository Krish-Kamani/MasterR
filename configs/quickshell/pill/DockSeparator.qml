pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

Rectangle {
    id: sep
    property real s: 1
    width: 1
    height: 22 * s
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: Theme.hair
}

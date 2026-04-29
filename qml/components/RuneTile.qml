// RuneTile.qml: One cell of the 6x6 board.
//
// Stateless visual: takes a tileType (0..4 -> colour) and emits a
// clicked(tileIndex) signal up to the GameScene. A short flash() is
// triggered when the player taps a too-small group (visual feedback
// without spending a move).

import QtQuick
import Felgo

Item {
    id: root

    property int  tileIndex: 0
    property int  tileType:  0
    property bool selected:  false
    property bool enabled:   true
    signal clicked(int tileIndex)

    width:  44
    height: 44

    // 5 rune palettes + a "void" colour for empty cells (tileType < 0
    // can briefly happen during clear-then-gravity).
    readonly property var palette: [
        "#69C17D",  // 0 green
        "#F0A04B",  // 1 orange
        "#7FA1CC",  // 2 blue
        "#C497F0",  // 3 violet
        "#E9648A"   // 4 pink
    ]

    function flash() { errorAnim.restart() }

    Rectangle {
        id: rune
        anchors.fill: parent
        anchors.margins: 2
        radius: 8
        color: tileType >= 0 ? root.palette[tileType] : "transparent"
        border.color: root.selected ? "white" : "#202833"
        border.width: root.selected ? 3 : 1
        antialiasing: true
        visible: tileType >= 0
    }

    // Brief red overlay on a too-small-group tap.
    Rectangle {
        id: errorOverlay
        anchors.fill: rune; radius: rune.radius
        color: "#D14242"; opacity: 0.0
    }
    SequentialAnimation {
        id: errorAnim
        NumberAnimation { target: errorOverlay; property: "opacity"; from: 0.0; to: 0.55; duration: 80 }
        NumberAnimation { target: errorOverlay; property: "opacity"; from: 0.55; to: 0.0; duration: 220 }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && tileType >= 0
        onClicked: root.clicked(root.tileIndex)
    }

    // Behavior on x/y; keep these even though the current Repeater
    // model binds tile position to a fixed (index -> row/column) slot.
    // The Behaviors are scaffolding for the stretch goal "real fall
    // animation" (index by stable tile-id, not slot, so a tile's row
    // actually changes after
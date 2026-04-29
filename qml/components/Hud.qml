// Hud.qml: Top score / moves / goal readout.

import QtQuick
import Felgo

Item {
    id: root

    property int score:     0
    property int bestScore: 0
    property int moves:     12
    property int goal:      800

    width:  parent ? parent.width : 320
    height: 64

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        color: "#1B1F2E"
        border.color: "#7FA1CC"
        border.width: 1
        radius: 10

        Text {
            anchors.top: parent.top
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Micro Match Alchemy"
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            color: "#9ACFFF"
            font.pixelSize: 14
            text: "SCORE  " + root.score
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            color: "#FFD166"
            font.pixelSize: 14
            text: "BEST  " + root.bestScore
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            color: "#DDFFEE"
            font.pixelSize: 12
            text: "Moves " + root.moves + "  -  Goal " + root.goal
        }
    }
}

// MenuOverlay.qml - Pre-game splash with PLAY button.

import QtQuick
import Felgo

Item {
    id: root
    signal startRequested()

    Rectangle {
        anchors.fill: parent
        color: "#0A1422"
        opacity: 0.92
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Micro Match Alchemy"
            color: "white"
            font.pixelSize: 26
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Tap groups of 3 or more connected runes."
            color: "#B7DAFF"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160; height: 48; radius: 24
            color: "#7FA1CC"
            border.color: "white"; border.width: 2
            Text {
                anchors.centerIn: parent
                text: "PLAY"; color: "white"
                font.pixelSize: 18; font.bold: true
            }
            MouseArea { anchors.fill: parent; onClicked: root.startRequested() }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "12 moves to reach 800.\nBigger groups score more."
            color: "#7FA1CC"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}

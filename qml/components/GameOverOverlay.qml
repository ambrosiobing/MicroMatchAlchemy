// GameOverOverlay.qml: Win/Lose summary + retry / menu.

import QtQuick
import Felgo

Item {
    id: root

    property bool wonGame:       false
    property int  finalScore:    0
    property int  bestScore:     0
    property int  movesLeft:     0
    property int  bestWinMoves:  -1   // -1 means no win on record yet
    signal retryRequested()
    signal menuRequested()

    Rectangle {
        anchors.fill: parent
        color: "#0A1422"
        opacity: 0.92
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.wonGame ? "Goal reached!" : "Out of moves"
            color: root.wonGame ? "#69C17D" : "#FFD166"
            font.pixelSize: 26
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Score:  " + root.finalScore
            color: "white"
            font.pixelSize: 18
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Best:  " + root.bestScore
            color: "#9ACFFF"
            font.pixelSize: 13
        }
        Text {
            visible: root.wonGame
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Moves remaining:  " + root.movesLeft +
                  (root.bestWinMoves > 0
                      ? "   (best so far: " + root.bestWinMoves + ")"
                      : "")
            color: "#69C17D"
            font.pixelSize: 12
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Rectangle {
                width: 120; height: 44; radius: 22
                color: "#69C17D"; border.color: "white"; border.width: 2
                Text {
                    anchors.centerIn: parent
                    text: "RETRY"; color: "white"
                    font.pixelSize: 16; font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: root.retryRequested() }
            }
            Rectangle {
                width: 120; height: 44; radius: 22
                color: "#3F5775"; border.color: "white"; border.width: 2
                Text {
                    anchors.centerIn: parent
                    text: "MENU"; color: "white"
                    font.pixelSize: 16; font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: root.menuRequested() }
            }
        }
    }
}

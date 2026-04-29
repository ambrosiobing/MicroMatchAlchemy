// GameScene.qml - MicroMatchAlchemy single playable scene.
//
// Owns:
//   - 6x6 board as a flat JS array of rune indices (0..4)
//   - Repeater(model: rows*columns) of RuneTile components
//   - 4-state machine: idle | playing | won | lost
//   - Tap routing via selectCell(index) which:
//       1. flood-fills the connected same-type group
//       2. if group < 3, flashes the tile red, no move spent
//       3. otherwise scores group.length^2 * 10, clears, gravity-refills,
//          decrements moves, checks win/lose
//   - Hud + MenuOverlay + GameOverOverlay
//   - Optional clear.wav SFX on group clear

import Felgo
import QtQuick
import QtMultimedia

import "../components"
import "../logic/Board.js" as Board

Scene {
    id: gameScene

    // 6 cols x 44 px tiles + 5 gaps + 2x6 margins =~ 290; round to 320 then
    // pad scene to 360 for HUD breathing.
    width:  360
    height: 540
    sceneAlignmentX: "center"
    sceneAlignmentY: "center"

    // -----------------------------------------------------------------
    // Public state - rules of the game
    // -----------------------------------------------------------------
    readonly property int rows:       6
    readonly property int columns:    6
    readonly property int runeTypes:  5
    readonly property int tileSize:   44
    readonly property int tileGap:    4

    property int    movesMax:    12
    property int    goalScore:   800

    property string phase:       "idle"   // idle | playing | won | lost
    property int    score:       0
    property int    bestScore:   0
    property int    bestWinMoves: -1
    property int    moves:       12
    property var    board:       []

    signal gameWon (int finalScore, int movesLeft)
    signal gameLost(int finalScore)

    // -----------------------------------------------------------------
    // Visuals
    // -----------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#181128" }
            GradientStop { position: 1.0; color: "#2C1F44" }
        }
    }

    Hud {
        id: hud
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        score:     gameScene.score
        bestScore: gameScene.bestScore
        moves:     gameScene.moves
        goal:      gameScene.goalScore
    }

    // The 6x6 board is centred under the HUD. We position each RuneTile
    // explicitly via x/y bindings (rather than a Grid layout) so the
    // tile's Behavior on x/y can animate the gravity-refill.
    Item {
        id: boardArea
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: hud.bottom
        anchors.topMargin: 24
        width:  gameScene.columns * (gameScene.tileSize + gameScene.tileGap) - gameScene.tileGap
        height: gameScene.rows    * (gameScene.tileSize + gameScene.tileGap) - gameScene.tileGap

        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            color: "#0E0820"
            border.color: "#7FA1CC"
            border.width: 1
            radius: 8
        }

        Repeater {
            id: boardRepeater
            model: gameScene.rows * gameScene.columns
            RuneTile {
                tileIndex: index
                tileType:  (gameScene.board && gameScene.board.length > index)
                            ? gameScene.board[index]
                            : 0
                width:  gameScene.tileSize
                height: gameScene.tileSize
                x: Board.columnOf(index, gameScene.columns) * (gameScene.tileSize + gameScene.tileGap)
                y: Board.rowOf   (index, gameScene.columns) * (gameScene.tileSize + gameScene.tileGap)
                enabled: gameScene.phase === "playing"
                onClicked: gameScene.selectCell(index)
            }
        }
    }

    // Hint text under the board. Doubles as a transient "reshuffled"
    // toast for ~2 s after an auto-reshuffle fires.
    Text {
        id: hintText
        anchors.top: boardArea.bottom
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 13
        color: hintToastActive ? "#FFD166" : "#DDFFEE"
        text: hintToastActive
              ? "No moves left on the board - reshuffled!"
              : phase === "idle"    ? ""
              : phase === "playing" ? "Tap groups of 3 or more"
              :                       ""
    }
    property bool hintToastActive: false
    Timer {
        id: hintToastTimer
        interval: 2200; repeat: false
        onTriggered: gameScene.hintToastActive = false
    }

    // RESTART button - always visible during play. Anchored BELOW the
    // hint text so the two don't fight for the same row. Lets the
    // player bail out of a hopeless run without sitting through the
    // moves countdown or quitting the app.
    Rectangle {
        id: restartBtn
        anchors.top: hintText.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: 110; height: 32; radius: 16
        color: "#3F5775"
        border.color: "white"; border.width: 1
        visible: gameScene.phase === "playing"
        opacity: 0.9
        Text {
            anchors.centerIn: parent
            text: "RESTART"; color: "white"
            font.pixelSize: 13; font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            onClicked: gameScene.startGame()
        }
    }

    // Low-latency game SFX - SoundEffect pre-decodes WAV into memory.
    // For longer/streaming audio (music, MP3) use MediaPlayer instead.
    // Missing file logs one load warning and play() is a silent no-op.
    //   Felgo SoundEffect: https://felgo.com/doc/felgo-soundeffect/
    //   Qt SoundEffect:    https://doc.qt.io/qt-6/qml-qtmultimedia-soundeffect.html
    SoundEffect {
        id: clearSfx
        source: Qt.resolvedUrl("../../assets/snd/clear.wav")
        volume: 0.6
    }

    // -----------------------------------------------------------------
    // Game logic
    // -----------------------------------------------------------------
    function startGame() {
        Board.setSeed(Date.now() & 0x7FFFFFFF)
        // Generate boards until we get one with at least one clearable
        // group. Worst-case probability of a deadlocked fresh board on
        // 6x6 with 5 rune types is ~1% per Monte Carlo, so the loop
        // almost always runs once. Capped at 8 attempts to be safe.
        var fresh = Board.makeBoard(rows, columns, runeTypes)
        var attempts = 0
        while (!Board.hasAnyMove(fresh, rows, columns) && attempts < 8) {
            fresh = Board.makeBoard(rows, columns, runeTypes)
            ++attempts
        }
        board = fresh
        score = 0
        moves = movesMax
        phas
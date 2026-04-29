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

    // Hint text under the board.
    Text {
        anchors.top: boardArea.bottom
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 13
        color: "#DDFFEE"
        text: phase === "idle"    ? ""
            : phase === "playing" ? "Tap groups of 3 or more"
            :                       ""
    }

    // Optional clear chirp. Same low-latency SoundEffect pattern as
    // MemoryGarden; missing file logs a single warning and is silent.
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
        board = Board.makeBoard(rows, columns, runeTypes)
        score = 0
        moves = movesMax
        phase = "playing"
    }

    function selectCell(index) {
        if (phase !== "playing") return
        if (!board || index < 0 || index >= board.length) return
        var group = Board.findGroup(board, index, rows, columns)
        if (group.length < 3) {
            // Visual feedback only - don't spend a move.
            var tile = boardRepeater.itemAt(index)
            if (tile) tile.flash()
            return
        }
        // Score, clear, gravity-refill, decrement moves, check end.
        score += Board.scoreFor(group.length)
        var next = board.slice()
        for (var i = 0; i < group.length; ++i) next[group[i]] = -1
        next = Board.applyGravity(next, rows, columns, runeTypes)
        board = next
        moves -= 1
        clearSfx.stop(); clearSfx.play()
        checkEnd()
    }

    function checkEnd() {
        if (score >= goalScore) {
            phase = "won"
            gameWon(score, moves)
        } else if (moves <= 0) {
            phase = "lost"
            gameLost(score)
        }
    }

    // -----------------------------------------------------------------
    // Overlays
    // -----------------------------------------------------------------
    MenuOverlay {
        anchors.fill: parent
        opacity: gameScene.phase === "idle" ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        onStartRequested: gameScene.startGame()
    }

    GameOverOverlay {
        anchors.fill: parent
        wonGame:      gameScene.phase === "won"
        finalScore:   gameScene.score
        bestScore:    gameScene.bestScore
        movesLeft:    gameScene.moves
        bestWinMoves: gameScene.bestWinMoves
        opacity: (gameScene.phase === "won" || gameScene.phase === "lost") ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        onRetryRequested: gameScene.startGame()
        onMenuRequested:  { gameScene.phase = "idle" }
    }
}

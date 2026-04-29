// Main.qml - MicroMatchAlchemy application root.
//
// Hosts a Storage singleton (best-score + best-win-moves persistence)
// and the single GameScene. No EntityManager / no PhysicsWorld - all
// state lives in the GameScene's flat board array.

import Felgo
import QtQuick

import "scenes"

GameWindow {
    id: root

    screenWidth:  360
    screenHeight: 540

    activeScene: gameScene

    // Felgo Storage is a key/value persistence layer backed by a local
    // SQLite database under QStandardPaths::AppDataLocation. Survives
    // app restarts; cleared with storage.clearAll().
    //   https://felgo.com/doc/felgo-storage/
    Storage {
        id: storage
        databaseName: "microMatchAlchemyStorage"
    }

    GameScene {
        id: gameScene

        onGameWon: function(finalScore, movesLeft) {
            var best = storage.getValue("bestScore") || 0
            if (finalScore > best) {
                storage.setValue("bestScore", finalScore)
                bestScore = finalScore
            }
            // Convention: bestWinMoves stores movesLeft (HIGHER = better,
            // i.e. won with the most moves to spare). Do NOT invert this
            // comparison - flipping to '<' would silently treat slow wins
            // as the new best and overwrite efficient runs.
            var bestMoves = storage.getValue("bestWinMoves") || -1
            if (bestMoves < 0 || movesLeft > bestMoves) {
                storage.setValue("bestWinMoves", movesLeft)
                bestWinMoves = movesLeft
            }
        }

        onGam
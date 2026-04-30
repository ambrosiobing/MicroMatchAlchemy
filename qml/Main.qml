// Main.qml: MicroMatchAlchemy application root.
//
// Hosts a Storage singleton (best-score + best-win-moves persistence)
// and the single GameScene. No EntityManager / no PhysicsWorld; all
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
            // comparison; flipping to '<' would silently treat slow wins
            // as the new best and overwrite efficient runs.
            var bestMoves = storage.getValue("bestWinMoves") || -1
            if (bestMoves < 0 || movesLeft > bestMoves) {
                storage.setValue("bestWinMoves", movesLeft)
                bestWinMoves = movesLeft
            }
        }

        onGameLost: function(finalScore) {
            // Even on a lost run, a high score survives. Best-win-moves is
            // NOT updated here; that field tracks winning runs only.
            var best = storage.getValue("bestScore") || 0
            if (finalScore > best) {
                storage.setValue("bestScore", finalScore)
                bestScore = finalScore
            }
        }

        Component.onCompleted: {
            // Hydrate the GameScene's display-bound properties from
            // persistent storage on first show. The scene reads these
            // for its HUD; without this hook the HUD would always start
            // at 0 / -1 even when the user has won previously.
            gameScene.bestScore    = storage.getValue("bestScore")    || 0
            gameScene.bestWinMoves = storage.getValue("bestWinMoves") || -1
        }
    }
}

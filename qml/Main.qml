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
            // Track fewest-moves win (a higher movesLeft means a faster win).
            var bestMoves = storage.getValue("bestWinMoves") || -1
            if (bestMoves < 0 || movesLeft > bestMoves) {
                storage.setValue("bestWinMoves", movesLeft)
                bestWinMoves = movesLeft
            }
        }

        onGameLost: function(finalScore) {
            var best = storage.getValue("bestScore") || 0
            if (finalScore > best) {
                storage.setValue("bestScore", finalScore)
                bestScore = finalScore
            }
        }

        Component.onCompleted: {
            gameScene.bestScore    = storage.getValue("bestScore")    || 0
            gameScene.bestWinMoves = storage.getValue("bestWinMoves") || -1
        }
    }
}

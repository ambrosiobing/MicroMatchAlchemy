// Board.js - Pure logic for the MicroMatchAlchemy 6x6 board.
//
// Everything random / mutating is exported; the GameScene calls into
// this module and reassigns its 'board' property after every change so
// QML bindings see the new array reference. Keeping the rules here
// (instead of inside GameScene.qml) makes the game unit-testable via
// QJSEngine - see _extras/tests/tst_Board.cpp.

.pragma library

// --- index helpers ---------------------------------------------------
function indexAt(row, col, columns) { return row * columns + col }
function rowOf(index, columns)      { return Math.floor(index / columns) }
function columnOf(index, columns)   { return index % columns }

// --- random helpers --------------------------------------------------
// Seedable mulberry32 so unit tests can pin the rune stream and assert
// exact-equality on generated boards.
var _seed = 0
function setSeed(s) { _seed = s | 0 }
function _rand() {
    var t = (_seed = (_seed + 0x6D2B79F5) | 0)
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
function newRune(runeTypes) { return Math.floor(_rand() * runeTypes) }

// --- board lifecycle -------------------------------------------------
function makeBoard(rows, columns, runeTypes) {
    var b = new Array(rows * columns)
    for (var i = 0; i < b.length; ++i) b[i] = newRune(runeTypes)
    return b
}

// --- flood-fill ------------------------------------------------------
// 4-neighbour breadth-first flood-fill from startIndex over cells of the
// same type. Cells with value < 0 are treated as empty and never join
// the group.
function neighbours(index, rows, columns) {
    var r = rowOf(index, columns)
    var c = columnOf(index, columns)
    var out = []
    if (r > 0)            out.push(indexAt(r - 1, c, columns))
    if (r < rows - 1)     out.push(indexAt(r + 1, c, columns))
    if (c > 0)            out.push(indexAt(r, c - 1, columns))
    if (c < columns - 1)  out.push(indexAt(r, c + 1, columns))
    return out
}
function findGroup(board, startIndex, rows, columns) {
    var wanted = board[startIndex]
    if (wanted < 0) return []
    // Iterative BFS, not recursive: a fully-connected board of one rune
    // type would recurse 36 deep on the spec 6x6 (and much further on
    // a hypothetical larger grid). Iterative keeps the JS stack out of
    // the picture and lets the algorithm scale linearly.
    var open  = [ startIndex ]
    var seen  = {}
    var group = []
    while (open.length > 0) {
        var idx = open.pop()
        if (seen[idx] || board[idx] !== wanted) continue
        seen[idx] = true
        group.push(idx)
        var ns = neighbours(idx, rows, columns)
        for (var i = 0; i < ns.length; ++i) open.push(ns[i])
    }
    return group
}

// --- score -----------------------------------------------------------
// Quadratic-in-length rewards strategic patience: 3 -> 90, 5 -> 250,
// 8 -> 640. A linear curve (length * 30) makes every 3-group worth
// clearing on sight, eliminating the only strategic verb the game
// has ("set up bigger blobs"). Don't flatten this without redesigning
// the level around it.
function scoreFor(groupLength) { return groupLength * groupLength * 10 }

// --- gravity + refill ------------------------------------------------
// Per-column compaction. Returns a NEW board so QML bindings refresh
// when the GameScene reassigns its 'board' property.
function applyGravity(board, rows, columns, runeTypes) {
    var out = board.slice()
    for (var col = 0; col < columns; ++col) {
        // Collect the surviving (non-(-1)) values from bottom to top.
        var kept = []
        for (var row = rows - 1; row >= 0; --row) {
            var v = out[indexAt(row, col, columns)]
            if (v >= 0) kept.push(v)
        }
        // Refill column: bottom -> top, pull from kept first then fresh.
        for (var writeRow = rows - 1; writeRow >= 0; --writeRow) {
            var next = (kept.length > 0) ? kept.shift() : newRune(runeTypes)
            out[indexAt(writeRow, col, columns)] = next
        }
    }
    return out
}

// --- validation ------------------------------------------------------
// Returns true if the current board has at lea
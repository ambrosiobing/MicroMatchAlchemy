# Micro Match Alchemy: Build a Felgo Tap-to-Clear Match Puzzle
> A 8-10 hour, step-by-step Felgo / QML (Qt Modeling Language)
tutorial showing how to build a tap-to-clear match-group puzzle with
flood-fill grouping, column gravity, refill, and a fixed-move
score-goal win condition.

This is the most logic-heavy of the five challenge prototypes; and
the most teachable. Every milestone (board generation, flood-fill,
gravity, refill, scoring) is a separate runnable checkpoint.

## What you will build

A 6x6 rune-matching puzzle:

- 6x6 board of runes (5 distinct types, hue-coded).
- Tap any group of 3+ connected same-type runes -> they clear.
- Tiles above fall down; new tiles refill from the top.
- 12 moves; score goal 800; win if score >= 800 before moves run out.
- Score formula: `group.length * group.length * 10`; bigger       groups score disproportionately more.

![](screenshots/04-final.png)

## Prerequisites

- Felgo SDK (Software Development Kit) 4.x installed on top of       Qt 6.8 with MinGW (Minimalist GNU for Windows) or MSVC       (Microsoft Visual C++) compiler kit.
- Qt Creator with a "Felgo Desktop Qt 6.x" kit registered.

## Step 1: Project root + config.json

`File -> New File or Project -> Felgo Games -> Empty Felgo Project`.
Name it `MicroMatchAlchemy`. Felgo SDK 4.x requires a `config`.json
next to the binary at runtime; ship a stub in the project root and
have `main`.cpp self-heal it to multiple paths so the SDK can find
it regardless of CWD (current working directory). Same pattern as
the other four prototypes.

## Step 2: Folder layout

```qml
qml/
  Main.qml
  scenes/GameScene.qml
  components/{RuneTile,Hud,MenuOverlay,GameOverOverlay}.qml
  logic/Board.js
```

## Step 3: Board.js (pure logic)

Isolate the rules so the game is testable. Index helpers, a seedable
mulberry32 RNG (random number generator), board generation,
flood-fill, scoring, gravity:
\code
.pragma library
function indexAt(row, col, columns) { return row * columns + col }
function rowOf(index, columns)      { return Math.floor(index / columns) }
function columnOf(index, columns)   { return index % columns }

var _seed = 0
function setSeed(s) { _seed = s | 0 }
function _rand() { /* mulberry32: small fast PRNG (pseudo-random number generator)

# Micro Match Alchemy

A small tap-to-clear match-group puzzle for the Felgo / Qt Software
Development Job Challenge. Tap connected groups of 3+ runes; clear
them; tiles fall, refill, and you try to hit the score goal before
your moves run out.

| | |
|---|---|
| Engine     | Felgo SDK (Software Development Kit) 4.x on Qt 6.8.3, MinGW (Minimalist GNU for Windows) 64-bit compiler |
| Resolution | 360 x 540 logical (auto-fits desktop and mobile)      |
| Platforms  | Desktop tested (Windows 11). Mobile-shaped layout     |
| Genre      | Tap-to-clear match-group puzzle                       |
| Inputs     | Tap or click. No keyboard required.                   |

## How to play

1. Press **PLAY**.
2. Tap any group of 3 or more **connected** same-coloured runes (4-way
   neighbours: up / down / left / right, no diagonals).
3. The group clears. Score added = `group.length` squared, times 10.
   So a 3-group is +90, a 5-group is +250, an 8-group is +640.
4. Tiles above the cleared group fall down; new runes refill from the
   top.
5. Each successful clear costs **one move**. Tapping a group of 1 or 2
   gives a red flash but **does not** spend a move, so go ahead and
   probe.
6. **Win** by reaching score >= **800** before moves run out.
7. **Lose** if moves hit 0 with score below 800.
8. Best score and best moves-remaining-on-win persist across launches
   via Felgo `Storage`.

## Build / run

### Requirements
- Felgo SDK 4.x installed at `C:\Felgo` (default Windows path) or set
  `FELGO_ROOT` before invoking `qmake`.
- Qt 6.8.3 with the MinGW 64-bit kit registered.

### From Qt Creator
Open `MicroMatchAlchemy.pro`, pick the
`Felgo_SDK_Desktop_Qt_6_8_3_MinGW_64_bit` kit, hit **Run**. The app
writes its run log to `<project>/logs/run_<timestamp>.log`; a copy of
the most recent log is kept at `<project>/logs/latest.log`.

### Felgo Live (Hot Reload)
Open `MicroMatchAlchemy.pro` in the Felgo Live client; saved QML
(Qt Modeling Language) changes propagate to the running app without
a full rebuild.

## Project layout

```
MicroMatchAlchemy/
├── MicroMatchAlchemy.pro       qmake project (Felgo + Qt 6 wiring)
├── main.cpp                    auto-logging + config.json self-heal
├── config.json                 Felgo SDK runtime stub
├── qml.qrc                     QML / config resource bundle
├── qml/
│   ├── Main.qml                GameWindow + Storage + GameScene
│   ├── scenes/
│   │   └── GameScene.qml       4-state machine + tap routing
│   ├── components/
│   │   ├── RuneTile.qml        one cell of the 6x6 grid
│   │   ├── Hud.qml             HUD (heads-up display) score / moves / goal
│   │   ├── MenuOverlay.qml     pre-game splash + PLAY button
│   │   └── GameOverOverlay.qml win / lose summary + RETRY / MENU
│   └── logic/
│       └── Board.js            pure flood-fill + gravity + scoring
├── docs/
│   ├── tutorial.qdoc           QDoc bonus tutorial source
│   ├── tutorial.html           rendered HTML for direct reading
│   ├── tutorial.md             markdown render
│   └── screenshots/            (5 PNG tutorial captures)
├── assets/
│   ├── img/                    sprite assets (none required)
│   └── snd/                    optional clear.wav SFX (sound effect)
├── README.md / LICENSE / .gitignore
└── logs/                       run logs auto-created on every launch
```

## Scoring formula

```
group.length        score
       3              90
       4             160
       5             250
       6             360
       7             490
       8             640
```

The quadratic curve makes large connected blobs strategically valuable:
chasing two 3-groups (180 total) is worse than waiting for one
6-group (360). Eight is the practical maximum on a 6x6 board with 5
rune types in a typical fresh refill.

## State machine

```
        +--------+    PLAY     +-----------+
        |  IDLE  |------------>|  PLAYING  |
        +--------+             +-----------+
             ^                       |
             |                       | score >= 800   moves == 0
             |                       v               v
             |                 +-----------+   +-----------+
             |                 |    WON    |   |   LOST    |
             |                 +-----------+   +-----------+
             |        RETRY/MENU   |       MENU       |
             +---------------------+------------------+
```

## License

Source code: MIT (see `LICENSE`).

Bundled audio: see `assets/snd/CREDITS.txt` for the 
# MicroMatchAlchemy.pro: qmake project file

TEMPLATE = app
TARGET   = MicroMatchAlchemy

CONFIG  += felgo
QT      += qml quick widgets multimedia

isEmpty(FELGO_ROOT): FELGO_ROOT = $$(FELGO_ROOT)
isEmpty(FELGO_ROOT): FELGO_ROOT = C:/Felgo
FELGO_KIT = $$FELGO_ROOT/Felgo/mingw_64

exists($$FELGO_KIT/include/Felgo/felgoapplication.h) {
    message("MicroMatchAlchemy: using Felgo SDK at $$FELGO_KIT")
    INCLUDEPATH   += $$FELGO_KIT/include
    INCLUDEPATH   += $$FELGO_KIT/include/Felgo
    QMAKEFEATURES += $$FELGO_KIT/mkspecs/features
    LIBS          += -L$$FELGO_KIT/lib -lFelgo
} else {
    warning("MicroMatchAlchemy: Felgo SDK not found at $$FELGO_KIT")
}

SOURCES += main.cpp

DISTFILES += \
    config.json \
    qml/Main.qml \
    qml/scenes/GameScene.qml \
    qml/components/RuneTile.qml \
    qml/components/Hud.qml \
    qml/components/MenuOverlay.qml \
    qml/components/GameOverOverlay.qml \
    qml/logic/Board.js \
    assets/snd/clear.wav \
    README.md \
    LICENSE \
    docs/tutorial.qdoc \
    docs/tutorial.md \
    docs/tutorial.html

RESOURCES += qml.qrc

ASSETS_DIR = $$PWD/assets
INCLUDEPATH += $$ASSETS_DIR

DEFINES += MMA_SOURCE_DIR=\\\"$$PWD\\\"

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

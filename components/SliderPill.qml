import "../config"
import QtQuick

// Slider em forma de pílula (volume/brilho). Arrasta e muda o preenchimento —
// FAKE: não toca em áudio/brilho reais. `value` em 0..1.
Item {
    id: root

    property string glyph: ""
    property real value: 0.5

    implicitHeight: 46
    implicitWidth: 260

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.accentTrack
        antialiasing: true
    }

    Rectangle {
        id: fill
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: Math.max(height, root.value * root.width)
        radius: height / 2
        color: Theme.accent
        antialiasing: true
        Behavior on width { NumberAnimation { duration: Theme.tFast } }
    }

    Text {
        anchors { left: parent.left; leftMargin: Theme.pad; verticalCenter: parent.verticalCenter }
        text: root.glyph
        font.family: Theme.iconFont
        font.pixelSize: 16
        color: Theme.textOnAccent
    }

    Text {
        anchors { right: parent.right; rightMargin: Theme.pad; verticalCenter: parent.verticalCenter }
        text: Math.round(root.value * 100) + "%"
        font.pixelSize: Theme.fsBodyLg
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (m) => root.value = Math.max(0, Math.min(1, m.x / width))
        onPositionChanged: (m) => root.value = Math.max(0, Math.min(1, m.x / width))
    }
}

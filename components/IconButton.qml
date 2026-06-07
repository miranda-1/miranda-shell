import "../config"
import QtQuick

// Botão de ícone da barra: glyph nerd-font centralizado, com highlight no hover
// (cresce levemente) e estado ativo em círculo clay sólido. Revela um tooltip
// lateral à direita — display-only, click-through — como nos prints #4–6.
Item {
    id: root

    property string glyph: ""
    property string label: ""
    property bool active: false
    property color glyphColor: Theme.text

    implicitWidth: Theme.barW
    implicitHeight: 40
    readonly property bool hovered: hover.hovered

    // estado "apagado" do highlight: MESMA cor do hover, porém com alfa 0.
    // Evita o flicker do hover — animar de/para "transparent" (#00000000)
    // interpola o RGB partindo do PRETO e pisca um tom escuro a cada enter/leave.
    // Com este token a ColorAnimation mexe só no alfa, sem flash.
    readonly property color hlClear: Qt.rgba(Theme.accentSoft.r, Theme.accentSoft.g, Theme.accentSoft.b, 0)

    // fundo highlight / ativo
    Rectangle {
        id: hl
        anchors.centerIn: parent
        width: Theme.iconSize + 18
        height: Theme.iconSize + 18
        antialiasing: true
        radius: root.active ? width / 2 : Theme.radiusSm
        color: tap.pressed && !root.active ? Theme.accentPressed
             : root.active ? Theme.accentActive
             : root.hovered ? Theme.accentSoft
             : root.hlClear
        scale: tap.pressed ? 0.94
             : (root.hovered && !root.active) ? 1.08
             : 1.0

        Behavior on color { ColorAnimation { duration: Theme.tFast } }
        Behavior on radius { NumberAnimation { duration: Theme.tFast } }
        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic} }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: root.active ? Theme.textOnAccent : root.glyphColor
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize
    }

    HoverHandler { id: hover }
    // captura o press só para feedback visual (pressed) — não dispara navegação:
    // os botões da barra são display-only nesta fase, comportamento inalterado.
    TapHandler { id: tap }

    // tooltip lateral (à direita do ícone)
    Item {
        id: tip
        visible: opacity > 0 && root.label.length > 0
        opacity: (root.hovered && root.label.length > 0) ? 1 : 0
        anchors.verticalCenter: parent.verticalCenter
        x: root.width + Theme.gap + (root.hovered ? 0 : -6)
        width: tipBg.width
        height: tipBg.height

        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
        Behavior on x { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutCubic} }

        Card {
            id: tipBg
            width: tipText.implicitWidth + Theme.pad * 2
            height: tipText.implicitHeight + Theme.gap * 2
            Text {
                id: tipText
                anchors.centerIn: parent
                text: root.label
                color: Theme.text
                font.pixelSize: 13
            }
        }
    }
}

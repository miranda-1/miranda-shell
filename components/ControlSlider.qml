import "../config"
import QtQuick

Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property real value: 0
    property string detail: ""
    property bool live: false
    // habilita o arrasto/clique na trilha e o clique no badge de %
    property bool interactive: false

    // quando true, a linha de detalhe vira clicável (para abrir um painel,
    // ex.: escolher a saída de áudio) e emite detailClicked()
    property bool expandable: false

    // quando true, o ícone vira botão de mudo (emite muteToggled); `muted`
    // controla o visual de mudo (ícone esmaecido + badge "Mudo")
    property bool muteEnabled: false
    property bool muted: false

    signal moved(real newValue)
    signal badgeClicked()
    signal detailClicked()
    signal muteToggled()

    radius: Theme.radius
    color: Theme.card
    border.width: 1
    border.color: Theme.stroke
    antialiasing: true
    implicitHeight: 96

    Column {
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.gap

        Row {
            width: parent.width
            spacing: Theme.gap

            Item {
                width: glyphText.implicitWidth
                height: glyphText.implicitHeight
                anchors.verticalCenter: undefined

                Text {
                    id: glyphText
                    text: root.glyph
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: root.muteEnabled && root.muted ? Theme.textFaint
                         : root.live ? Theme.accent : Theme.textDim

                    Behavior on color { ColorAnimation { duration: Theme.tFast } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: root.muteEnabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }

            Text {
                text: root.label
                font.pixelSize: Theme.fsLabel
                color: Theme.text
            }

            Item { width: Math.max(0, parent.width - percentBadge.width - 120); height: 1 }

            Rectangle {
                id: percentBadge
                width: percentText.implicitWidth + 16
                height: 24
                radius: 12
                color: root.live ? Theme.accentSoft : Theme.accentTrack

                Text {
                    id: percentText
                    anchors.centerIn: parent
                    text: root.muteEnabled && root.muted
                        ? "Mudo"
                        : Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
                    font.pixelSize: 11
                    color: root.live ? Theme.accentActive : Theme.textDim
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    enabled: root.interactive
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.badgeClicked()
                }
            }
        }

        Rectangle {
            id: track
            width: parent.width
            height: 12
            radius: 6
            color: Theme.accentTrack
            antialiasing: true

            Rectangle {
                width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
                height: parent.height
                radius: parent.radius
                color: root.live ? Theme.accentActive : Theme.accent
                opacity: root.live ? 1 : 0.5
                antialiasing: true
                Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
            }

            // clique/arrasto em qualquer ponto da trilha define o valor
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                enabled: root.interactive
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function emitFromX(x) {
                    root.moved(Math.max(0, Math.min(1, x / track.width)));
                }

                onPressed: (mouse) => emitFromX(mouse.x)
                onPositionChanged: (mouse) => {
                    if (pressed)
                        emitFromX(mouse.x);
                }
            }
        }

        Text {
            id: detailText
            width: parent.width
            visible: root.detail.length > 0
            text: root.expandable ? root.detail + "  ›" : root.detail
            font.pixelSize: Theme.fsBody
            color: root.expandable && detailHover.hovered ? Theme.text : Theme.textDim
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: Theme.tFast } }

            HoverHandler {
                id: detailHover
                enabled: root.expandable
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: root.expandable
                acceptedButtons: Qt.LeftButton
                onTapped: root.detailClicked()
            }
        }
    }
}

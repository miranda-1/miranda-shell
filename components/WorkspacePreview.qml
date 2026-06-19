import "../config"
import "../services"
import Quickshell.Wayland
import QtQuick

// Mini-mapa de um workspace: reproduz a tela em miniatura, posicionando cada
// janela na sua geometria real (at/size do Hyprland, escalada para o monitor).
// Janelas do workspace ativo aparecem ao vivo (ScreencopyView); as ocultas não
// renderizam → caem no fallback (retângulo + inicial do app). É só visual; o
// clique de focar fica no card pai.
Item {
    id: root

    required property var workspace
    readonly property var monitor: root.workspace && root.workspace.monitor ? root.workspace.monitor : null

    // dimensões lógicas do monitor (px físicos / escala).
    readonly property real monX: root.monitor ? root.monitor.x : 0
    readonly property real monY: root.monitor ? root.monitor.y : 0
    readonly property real logicalW: (root.monitor && root.monitor.scale > 0)
                                     ? root.monitor.width / root.monitor.scale : 1920
    readonly property real logicalH: (root.monitor && root.monitor.scale > 0)
                                     ? root.monitor.height / root.monitor.scale : 1080
    // fator de escala miniatura: largura do item / largura lógica.
    readonly property real s: (width > 0 && root.logicalW > 0) ? width / root.logicalW : 0

    // a altura segue o aspecto real do monitor.
    implicitHeight: root.logicalW > 0 ? Math.round(width * root.logicalH / root.logicalW) : width * 0.5625
    clip: true

    // fundo da "tela"
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.accentTrack
    }

    Repeater {
        model: Hyprland.workspaceToplevels(root.workspace)
        delegate: Item {
            id: win
            required property var modelData
            readonly property var o: modelData.lastIpcObject
            readonly property bool ok: !!(o && o.at && o.size && o.size[0] > 0 && o.size[1] > 0)

            visible: ok
            x: ok ? (o.at[0] - root.monX) * root.s : 0
            y: ok ? (o.at[1] - root.monY) * root.s : 0
            width: ok ? o.size[0] * root.s : 0
            height: ok ? o.size[1] * root.s : 0
            clip: true

            // moldura/fundo de cada janela
            Rectangle {
                anchors.fill: parent
                color: Theme.card
                border.width: 1
                border.color: Theme.strokeStrong
            }

            ScreencopyView {
                id: view
                anchors.fill: parent
                anchors.margins: 1
                captureSource: win.modelData.wayland
                live: true
                paintCursor: false
                visible: hasContent
            }

            // fallback quando não há frame (workspace oculto)
            Text {
                anchors.centerIn: parent
                visible: !view.hasContent
                text: Hyprland.toplevelLabel(win.modelData).charAt(0).toUpperCase()
                font.pixelSize: Math.max(Theme.fsBody, Math.min(parent.height, parent.width) * 0.4)
                font.bold: true
                color: Theme.textDim
            }
        }
    }
}

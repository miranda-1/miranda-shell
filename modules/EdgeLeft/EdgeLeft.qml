import "../../config"
import "../../components"
import "../../services"
import Quickshell
import Quickshell.Wayland
import QtQuick

// Barra vertical principal (estilo dos prints): fina e sempre presente.
// Topo: logo + apps (ativo em círculo clay) + dots de workspace.
// Centro: label "Desktop" + monitor. Base: tray + relógio empilhado + status +
// power. Hover destaca o ícone e revela tooltip lateral. Dados FAKE (leva A).
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors { left: true; top: true; bottom: true }
    exclusiveZone: Theme.barW                       // reserva só a barra fina
    implicitWidth: Theme.barW + Theme.tooltipReserve // resto = área de tooltip
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top

    // só a barra fina captura mouse; o resto da janela é click-through
    mask: Region { x: 0; y: 0; width: Theme.barW; height: root.height }

    // casca visível da barra: uma "pill" vertical maior, cortada pela borda
    // esquerda do monitor. A parte arredondada esquerda do barBg fica em x<0
    // (fora da janela), então o lado esquerdo já lê como reto SEM precisar de
    // clip. Mantemos clip:false para os tooltips (filhos em x≥barW) renderizarem
    // na área de reserva à direita em vez de serem recortados pela casca.
    Item {
        id: shellShape
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: Theme.barW
        clip: false

        Rectangle {
            id: barBg
            anchors { top: parent.top; bottom: parent.bottom }
            x: -30
            width: Theme.barW + 30
            radius: Theme.screenRound + 8
            antialiasing: true
            color: Theme.bar
            border.width: 1
            border.color: Theme.stroke
        }

        Item {
            anchors.fill: parent

            // ---- topo: logo + apps + workspaces ----
            Column {
                id: topCol
                anchors { top: parent.top; topMargin: Theme.gap; horizontalCenter: parent.horizontalCenter }
                spacing: 2

                IconButton { glyph: ""; glyphColor: Theme.accent; label: "Arch Linux" }
                Item { width: 1; height: Theme.gap }
                IconButton { glyph: ""; label: "Terminal" }
                IconButton { glyph: ""; label: "Navegador" }
                IconButton { glyph: ""; label: "Arquivos" }
                IconButton { glyph: ""; active: true; label: "Editor (ativo)" }
                // divisor sutil: separa o grupo de apps dos workspaces
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.iconSize; height: Theme.gap
                    Divider { anchors.centerIn: parent }
                }

                // dots de workspace
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7
                    Repeater {
                        model: [true, false, false]
                        delegate: Rectangle {
                            required property var modelData
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: modelData ? 7 : 6
                            height: width
                            radius: width / 2
                            antialiasing: true
                            color: modelData ? Theme.accent : Theme.textFaint
                        }
                    }
                }
            }

            // ---- centro: label Desktop ----
            Column {
                anchors.centerIn: parent
                spacing: Theme.gap
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Monitor: eDP-1" }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Desktop"
                    color: Theme.textDim
                    font.pixelSize: 12
                    rotation: -90
                }
            }

            // ---- base: tray + relógio + status + power ----
            Column {
                id: bottomCol
                anchors { bottom: parent.bottom; bottomMargin: Theme.gap; horizontalCenter: parent.horizontalCenter }
                spacing: 2

                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Bluetooth" }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "SafeEyes" }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Discord" }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "HyDE" }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Spotify" }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Calendário" }

                // divisor sutil: separa o tray do relógio/status
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.iconSize; height: Theme.gap
                    Divider { anchors.centerIn: parent }
                }

                // relógio empilhado 21 / 40
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: -1
                    topPadding: Theme.gap / 2
                    bottomPadding: Theme.gap / 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clock.hour; color: Theme.text
                        font.pixelSize: 15; font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clock.minute; color: Theme.textDim
                        font.pixelSize: 15
                    }
                }

                IconButton { glyph: ""; glyphColor: Theme.textDim; label: Network.statusText }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Bluetooth" }
                IconButton { glyph: ""; glyphColor: Theme.accent; label: "Perfil: " + Battery.profileText }
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Desligar" }
            }
        }
    }
}

import "../../config"
import "../../components"
import Quickshell
import Quickshell.Wayland
import QtQuick

// Launcher: faixa de hover no rodapé-centro faz um painel SUBIR (slide-up +
// fade). Campo de busca + lista de apps — tudo FAKE, nada executa.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 0
    implicitHeight: 540
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    // Foco de teclado SÓ quando aberto → permite Esc fechar, sem roubar teclas
    // das janelas atrás (terminal/browser) em repouso. OnDemand = o compositor
    // concede o foco no clique que abre; None = não interfere.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property int sliverW: 220
    readonly property int gripHotspotH: 18   // altura da zona clicável do puxador (repouso)

    // Abertura por CLIQUE no puxador (não por hover). `open` é alternado pelo
    // TapHandler da zona do grip; hover é só feedback visual. Esc e clique-fora
    // fecham. Sem timers de hover: a abertura é sempre intencional.
    property bool open: false
    function toggle() { root.open = !root.open }
    function close() { root.open = false }

    // Máscara DESACOPLADA da animação do card (essa dependência causava o loop
    // abre/fecha sobre janelas atrás). Fechado = só o hotspot do puxador no
    // rodapé-centro → resto da tela é click-through. Aberto = a JANELA inteira:
    // região sólida e estável (não segue o card que desliza); clicar fora do
    // card fecha.
    mask: Region {
        x: root.open ? 0 : Math.round((root.width - root.sliverW) / 2)
        y: root.open ? 0 : (root.height - root.gripHotspotH)
        width: root.open ? root.width : root.sliverW
        height: root.open ? root.height : root.gripHotspotH
    }

    // Fundo de captura: ativo só quando aberto. Clique em qualquer ponto FORA do
    // card fecha o launcher. Declarado primeiro → fica ATRÁS do card e do grip.
    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.close()
    }

    // Esc fecha. Precisa de um item com foco ativo; o foco de teclado é concedido
    // pelo compositor (keyboardFocus OnDemand) no clique que abre o painel.
    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.close()
    }

    // Zona do puxador: área clicável que coincide com a máscara fechada (mais
    // fácil de acertar que a linha de 3px). Clique alterna abrir/fechar; hover é
    // só feedback visual. Some quando aberto.
    Item {
        id: gripZone
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        width: root.sliverW
        height: root.gripHotspotH
        opacity: root.open ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

        HoverHandler { id: gripHover }
        TapHandler { onTapped: root.toggle() }

        // linha fina visível do puxador, centrada na zona
        Rectangle {
            id: grip
            anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter }
            width: Theme.gripLen
            height: Theme.gripThickness
            radius: height / 2
            antialiasing: true
            color: gripHover.hovered ? Theme.gripHover : Theme.gripColor
            scale: gripHover.hovered ? 1.04 : 1.0
            Behavior on color { ColorAnimation { duration: Theme.tFast } }
            Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
        }
    }

    Card {
        id: card
        width: 680
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.open ? Theme.gap : -(height + 30)
        opacity: root.open ? 1 : 0
        // painel sólido + contorno mais nítido: sem blur real, isso separa o
        // launcher das janelas atrás (terminal/browser) e mata o efeito fantasma.
        color: Theme.surfaceStrong
        border.color: Theme.strokeStrong
        height: col.implicitHeight + Theme.pad * 2

        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

        // engole cliques dentro do card → não chegam ao fundo de captura, então
        // clicar no painel NÃO fecha. Fica atrás da Column (hover das linhas intacto).
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad }
            spacing: Theme.gap

            // resultados (fake)
            Repeater {
                model: [
                    { glyph: "", title: "Wallpaper", sub: "Change the current wallpaper" },
                    { glyph: "", title: "Files", sub: "Browse your files" },
                    { glyph: "", title: "Terminal", sub: "Open a terminal session" },
                    { glyph: "", title: "Settings", sub: "System configuration" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 58
                    radius: Theme.radiusSm
                    antialiasing: true
                    color: rowHover.hovered ? Theme.accentSoft : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.tFast } }

                    HoverHandler { id: rowHover }

                    Row {
                        anchors { left: parent.left; leftMargin: Theme.pad; verticalCenter: parent.verticalCenter }
                        spacing: Theme.pad
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38; height: 38; radius: Theme.radiusSm
                            antialiasing: true
                            color: Theme.card
                            Text { anchors.centerIn: parent; text: modelData.glyph; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.accent }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text { text: modelData.title; font.pixelSize: 15; color: Theme.text }
                            Text { text: modelData.sub; font.pixelSize: 12; color: Theme.textDim }
                        }
                    }
                }
            }

            // campo de busca (fake)
            Rectangle {
                width: parent.width
                height: 50
                radius: height / 2
                antialiasing: true
                color: Theme.accentTrack
                Row {
                    anchors { left: parent.left; leftMargin: Theme.pad + 4; verticalCenter: parent.verticalCenter }
                    spacing: Theme.gap
                    Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.textDim }  // lupa
                    Text { anchors.verticalCenter: parent.verticalCenter; text: ">wa"; font.pixelSize: 15; color: Theme.text }
                }
                Text {
                    anchors { right: parent.right; rightMargin: Theme.pad + 4; verticalCenter: parent.verticalCenter }
                    text: ""   // x
                    font.family: Theme.iconFont
                    font.pixelSize: 14
                    color: Theme.textDim
                }
            }
        }
    }
}

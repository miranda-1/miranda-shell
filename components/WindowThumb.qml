import "../config"
import "../services"
import Quickshell.Wayland
import QtQuick

// Card de janela (visão "alt-tab"): preview ao vivo via ScreencopyView +
// rótulo do app. Clique foca a janela. Janelas em workspaces ocultos podem
// não renderizar → cai no fallback com a inicial do app.
Rectangle {
    id: root

    // toplevel Wayland (captureSource do ScreencopyView). Pode ser null se a
    // janela não expõe handle Wayland — aí mostra só o fallback.
    required property var toplevel
    // rótulo explícito (ex.: class do Hyprland). Vazio → deriva do toplevel.
    property string labelText: ""
    // estado ativo — sobrescrevível por quem conhece melhor (Hyprland).
    property bool active: Windows.isActive(root.toplevel)

    readonly property string label: root.labelText !== ""
                                     ? root.labelText : Windows.appLabel(root.toplevel)

    signal activated()

    radius: Theme.radius
    antialiasing: true
    clip: true
    color: Theme.card
    border.width: 1
    border.color: root.active ? Theme.accentActive : Theme.stroke

    HoverHandler {
        id: thumbHover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    // ---- área de preview ----
    Item {
        id: previewBox
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: labelRow.top }
        anchors.margins: 1
        clip: true

        ScreencopyView {
            id: view
            anchors.centerIn: parent
            captureSource: root.toplevel
            live: true
            paintCursor: false

            // mantém o aspecto da janela dentro da caixa (fit/contain).
            readonly property real ar: (sourceSize.width > 0 && sourceSize.height > 0)
                                       ? sourceSize.width / sourceSize.height : (16 / 9)
            width: Math.min(previewBox.width, previewBox.height * ar)
            height: width / ar
            visible: hasContent
        }

        // fallback quando não há frame (workspace oculto / app sem render)
        Rectangle {
            anchors.fill: parent
            visible: !view.hasContent
            color: Theme.accentTrack
            Text {
                anchors.centerIn: parent
                text: root.label.charAt(0).toUpperCase()
                font.pixelSize: Theme.fsDisplay
                font.bold: true
                color: Theme.textDim
            }
        }
    }

    // sutil realce no hover sobre o preview
    Rectangle {
        anchors.fill: previewBox
        color: thumbHover.hovered ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.tFast } }
    }

    // ---- rótulo ----
    Row {
        id: labelRow
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 38
        leftPadding: Theme.pad
        rightPadding: Theme.pad
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: 8; radius: 4
            visible: root.active
            color: Theme.accentActive
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: labelRow.width - labelRow.leftPadding - labelRow.rightPadding
                   - (root.active ? 16 : 0)
            text: root.label
            elide: Text.ElideRight
            font.pixelSize: Theme.fsLabel
            font.bold: root.active
            color: Theme.text
        }
    }
}

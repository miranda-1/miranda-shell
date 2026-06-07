import "../../config"
import "../../components"
import "../../services"
import Quickshell
import Quickshell.Wayland
import QtQuick

// Barra vertical principal (estilo dos prints): fina e sempre presente.
// Topo: logo + apps (ativo em círculo clay) + dots de workspace reais.
// Centro: label "Desktop" + monitor. Base: tray + relógio empilhado + status +
// power. Hover destaca o ícone e revela tooltip lateral.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    readonly property string screenMonitorName: Hyprland.monitorNameForScreen(root.screen)
    readonly property var workspaceDots: Hyprland.workspacesForScreen(root.screen)
    readonly property bool hasRealWorkspaces: root.workspaceDots.length > 0
    readonly property var fallbackWorkspaceDots: [
        { label: "1", active: true, focused: true },
        { label: "2", active: false, focused: false },
        { label: "3", active: false, focused: false }
    ]
    readonly property var visibleWorkspaceDots: root.workspaceDots.length > 0 ? root.workspaceDots : root.fallbackWorkspaceDots
    readonly property bool hasActiveWindow: Hyprland.activeWindowTitle !== "Sem janela ativa"
    readonly property string activeWindowTooltip: root.hasActiveWindow
        ? "App: " + Hyprland.activeWindowClass + "\nJanela: " + Hyprland.activeWindowTitle
        : "Sem janela ativa"

    function workspaceTooltipText(workspace, realWorkspace, activeWorkspace, focusedWorkspace) {
        const label = realWorkspace ? Hyprland.workspaceLabel(workspace) : (workspace && workspace.label ? workspace.label : "\u2014");
        const lines = ["Workspace " + label];

        if (!realWorkspace) {
            lines.push("Estado: " + (focusedWorkspace ? "focused" : activeWorkspace ? "active" : "idle"));
            return lines.join("\n");
        }

        const windows = Hyprland.workspaceWindowCount(workspace);
        const states = [];
        if (focusedWorkspace)
            states.push("focused");
        else if (activeWorkspace)
            states.push("active");

        if (Hyprland.isWorkspaceUrgent(workspace))
            states.push("urgent");

        states.push(windows > 0 ? "ocupado" : "vazio");

        lines.push("Monitor: " + (workspace && workspace.monitor && workspace.monitor.name ? workspace.monitor.name : root.screenMonitorName));
        lines.push("Janelas: " + windows);
        lines.push("Estado: " + states.join(", "));
        return lines.join("\n");
    }

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
                IconButton {
                    glyph: ""
                    active: root.hasActiveWindow
                    glyphColor: root.hasActiveWindow ? Theme.accent : Theme.textDim
                    label: root.activeWindowTooltip
                }
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
                        model: root.visibleWorkspaceDots
                        delegate: Item {
                            required property var modelData
                            readonly property bool realWorkspace: modelData && modelData.monitor !== undefined
                            readonly property bool activeWorkspace: realWorkspace ? Hyprland.isWorkspaceActive(modelData) : !!modelData.active
                            readonly property bool focusedWorkspace: realWorkspace ? Hyprland.isWorkspaceFocused(modelData) : !!modelData.focused
                            readonly property bool urgentWorkspace: realWorkspace ? Hyprland.isWorkspaceUrgent(modelData) : false
                            readonly property int workspaceWindows: realWorkspace ? Hyprland.workspaceWindowCount(modelData) : 0
                            readonly property bool workspaceHasWindows: realWorkspace ? Hyprland.workspaceHasWindows(modelData) : false
                            readonly property string workspaceText: root.workspaceTooltipText(modelData, realWorkspace, activeWorkspace, focusedWorkspace)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: urgentWorkspace ? 10 : 8
                            height: width

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.focusedWorkspace ? 8 : parent.activeWorkspace ? 7 : parent.workspaceHasWindows ? 6 : 5
                                height: width
                                radius: width / 2
                                antialiasing: true
                                color: parent.focusedWorkspace
                                    ? Theme.accentActive
                                    : parent.activeWorkspace
                                        ? Theme.accent
                                        : parent.workspaceHasWindows
                                            ? Theme.textDim
                                            : Theme.textFaint
                                border.width: parent.urgentWorkspace ? 1 : 0
                                border.color: Theme.accentActive
                                scale: parent.focusedWorkspace ? 1.0 : parent.activeWorkspace ? 0.97 : parent.workspaceHasWindows ? 0.94 : 0.9

                                Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: Theme.tFast } }
                                Behavior on border.width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                            }

                            HoverHandler { id: workspaceHover }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Theme.barW + Theme.gap + (workspaceHover.hovered ? 0 : -6)
                                width: Math.min(tipText.implicitWidth, 240) + Theme.pad * 2
                                height: tipText.implicitHeight + Theme.gap * 2
                                radius: Theme.radiusSm
                                color: Theme.accentActive
                                border.width: 1
                                border.color: Theme.strokeStrong
                                opacity: workspaceHover.hovered ? 1 : 0
                                visible: opacity > 0

                                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
                                Behavior on x { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutCubic } }

                                Text {
                                    id: tipText
                                    anchors.centerIn: parent
                                    text: parent.parent.workspaceText
                                    color: Theme.textOnAccent
                                    font.pixelSize: 12
                                    width: Math.min(implicitWidth, 240)
                                }
                            }
                        }
                    }
                }
            }

            // ---- centro: label Desktop ----
            Column {
                anchors.centerIn: parent
                spacing: Theme.gap
                IconButton { glyph: ""; glyphColor: Theme.textDim; label: "Monitor: " + root.screenMonitorName }
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

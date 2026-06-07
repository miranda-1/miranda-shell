import "../../config"
import "../../components"
import "../../services"
import "../Dashboard"
import Quickshell
import Quickshell.Wayland
import QtQuick

// Borda superior: faixa de hover no topo-centro abre um drawer (overlay) que
// desce com slide-down + fade. Abas Dashboard/Media/Performance/Workspaces.
// Não reserva espaço (exclusiveZone 0); máscara restrita à faixa/drawer.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    readonly property var monitorList: Hyprland.monitors && Hyprland.monitors.values ? Hyprland.monitors.values : []
    readonly property var workspaceList: Hyprland.workspaceList
    readonly property var fallbackWorkspaceList: [
        { label: "1", active: true, focused: true, windows: 2, monitorName: root.screen && root.screen.name ? root.screen.name : "\u2014" },
        { label: "2", active: false, focused: false, windows: 1, monitorName: root.screen && root.screen.name ? root.screen.name : "\u2014" },
        { label: "3", active: false, focused: false, windows: 0, monitorName: root.screen && root.screen.name ? root.screen.name : "\u2014" }
    ]
    readonly property var visibleWorkspaceList: root.workspaceList.length > 0 ? root.workspaceList : root.fallbackWorkspaceList

    function monitorResolutionText(monitor) {
        if (!monitor)
            return "\u2014";

        const width = Number(monitor.width);
        const height = Number(monitor.height);
        if (Number.isNaN(width) || Number.isNaN(height) || width <= 0 || height <= 0)
            return "\u2014";

        return Math.trunc(width) + "\u00d7" + Math.trunc(height);
    }

    function monitorScaleText(monitor) {
        if (!monitor)
            return "\u2014";

        const scale = Number(monitor.scale);
        if (Number.isNaN(scale) || scale <= 0)
            return "\u2014";

        return scale.toFixed(2) + "x";
    }

    function monitorWorkspaceText(monitor) {
        if (monitor && monitor.activeWorkspace)
            return "Workspace " + Hyprland.workspaceLabel(monitor.activeWorkspace);

        return "Workspace \u2014";
    }

    function workspaceStateText(workspace, realWorkspace) {
        if (!realWorkspace)
            return workspace && workspace.focused ? "focused" : workspace && workspace.active ? "active" : "idle";

        const states = [];
        if (Hyprland.isWorkspaceFocused(workspace))
            states.push("focused");
        else if (Hyprland.isWorkspaceActive(workspace))
            states.push("active");

        if (Hyprland.isWorkspaceUrgent(workspace))
            states.push("urgent");

        states.push(Hyprland.workspaceHasWindows(workspace) ? "ocupado" : "vazio");
        return states.join(" \u00b7 ");
    }

    anchors { top: true; left: true; right: true }
    exclusiveZone: 0
    implicitHeight: 640
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top

    // faixa de gatilho estreita, perto do puxador visível — não a meia-tela toda,
    // pra não abrir o drawer ao mirar a área central por outros motivos.
    readonly property int stripW: 260
    property int tab: 0
    // hover com atraso: evita abrir o drawer só ao passar o mouse no topo
    property bool hovering: stripHover.hovered || drawerHover.hovered
    property bool open: false
    Timer { id: openTimer; interval: Theme.tHoverOpen; onTriggered: root.open = true }
    onHoveringChanged: {
        if (root.hovering) openTimer.start()
        else { openTimer.stop(); root.open = false }
    }

    mask: Region {
        x: root.open ? Math.round(drawer.x) : Math.round((root.width - root.stripW) / 2)
        y: 0
        width: root.open ? Math.ceil(drawer.width) : root.stripW
        height: root.open ? Math.ceil(drawer.height) : 14
    }

    // faixa de hover (topo-centro) — invisível e um pouco mais alta p/ mira fácil
    Item {
        id: strip
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        width: root.stripW
        height: 14
        HoverHandler { id: stripHover }
    }

    // puxador autônomo: discreto, sem depender de moldura contínua
    Rectangle {
        id: grip
        anchors { top: parent.top; topMargin: 7; horizontalCenter: parent.horizontalCenter }
        width: Theme.gripLen
        height: Theme.gripThickness
        radius: height / 2
        antialiasing: true
        color: root.open ? Theme.gripHover : Theme.gripColor
        opacity: root.open ? 0 : 1
        scale: stripHover.hovered ? 1.04 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.tFast } }
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
    }

    // drawer
    Card {
        id: drawer
        anchors.horizontalCenter: parent.horizontalCenter
        width: 880
        height: 470
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.radiusLg
        bottomRightRadius: Theme.radiusLg
        y: root.open ? 0 : -height - 16
        opacity: root.open ? 1 : 0

        HoverHandler { id: drawerHover }
        Behavior on y { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

        // abas
        Row {
            id: tabbar
            anchors { top: parent.top; topMargin: Theme.gap; horizontalCenter: parent.horizontalCenter }
            spacing: Theme.pad
            TabButton { glyph: ""; label: "Dashboard";   active: root.tab === 0; onClicked: root.tab = 0 }
            TabButton { glyph: ""; label: "Media";       active: root.tab === 1; onClicked: root.tab = 1 }
            TabButton { glyph: ""; label: "Performance"; active: root.tab === 2; onClicked: root.tab = 2 }
            TabButton { glyph: ""; label: "Workspaces";  active: root.tab === 3; onClicked: root.tab = 3 }
        }

        Divider {
            id: divider
            // mesmas medidas do divisor inline anterior: recuo de Theme.pad nos
            // dois lados (largura = parent - 2*pad, centralizado → esquerda em pad).
            anchors { top: tabbar.bottom; topMargin: Theme.gap / 2; horizontalCenter: parent.horizontalCenter }
            width: parent.width - Theme.pad * 2
            height: 1
        }

        // conteúdo das abas
        Item {
            id: content
            anchors { top: divider.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.pad }

            // 0 — Dashboard
            Dashboard {
                anchors.centerIn: parent
                visible: opacity > 0
                opacity: root.tab === 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
            }

            // 1 — Media
            Row {
                anchors.centerIn: parent
                spacing: 44
                visible: opacity > 0
                opacity: root.tab === 1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 160; height: 160; radius: 80
                    antialiasing: true
                    color: Theme.accentSoft
                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.iconFont; font.pixelSize: 60; color: Theme.accent }  // nota
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Text { text: Media.available ? Media.title : "Nada tocando"; font.pixelSize: 22; color: Theme.text }
                    Text { text: Media.album; font.pixelSize: 14; color: Theme.textDim }
                    Text { text: Media.artist; font.pixelSize: 14; color: Theme.textDim }
                    Row {
                        spacing: Theme.pad + 6
                        topPadding: 6
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 22; color: Theme.textDim }  // prev
                        Text { text: Media.isPlaying ? "" : ""; font.family: Theme.iconFont; font.pixelSize: 28; color: Theme.accent }   // estado play/pause (read-only)
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 22; color: Theme.textDim }  // next
                    }
                    Row {
                        spacing: Theme.gap
                        topPadding: 6
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Media.positionText; font.pixelSize: 12; color: Theme.textDim }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 280; height: 5; radius: 3; color: Theme.accentTrack
                            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: parent.width * Media.progress; radius: 3; color: Theme.accent }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: Media.lengthText; font.pixelSize: 12; color: Theme.textDim }
                    }
                }
            }

            // 2 — Performance
            Row {
                anchors.centerIn: parent
                spacing: 40
                visible: opacity > 0
                opacity: root.tab === 2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

                RingMeter { value: 0.54; big: "54°C"; sub: "GPU temp" }
                RingMeter { value: 0.41; big: "41°C"; sub: "CPU temp" }
                RingMeter { value: 0.23; big: "5.4GiB"; sub: "Memory" }
            }

            // 3 — Workspaces / estado do Hyprland
            Item {
                anchors.fill: parent
                visible: opacity > 0
                opacity: root.tab === 3 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

                Flickable {
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: workspaceTabContent.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: workspaceTabContent
                        width: parent.width
                        spacing: Theme.gap

                        Row {
                            id: summaryRow
                            property int windowCardWidth: Math.round((width - Theme.gap) * 0.42)
                            width: parent.width
                            spacing: Theme.gap

                            Rectangle {
                                width: summaryRow.windowCardWidth
                                height: 118
                                radius: Theme.radiusSm
                                antialiasing: true
                                color: Theme.card
                                border.width: 1
                                border.color: Theme.stroke

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Theme.pad
                                    spacing: 6

                                    Text {
                                        text: "Janela ativa"
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                    }

                                    Text {
                                        text: Hyprland.activeWindowTitle
                                        font.pixelSize: 17
                                        color: Theme.text
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: "App: " + Hyprland.activeWindowClass
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: "Monitor focado: " + Hyprland.focusedMonitorName
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: "Workspace ativo: " + Hyprland.activeWorkspaceLabel
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            Rectangle {
                                width: summaryRow.width - summaryRow.windowCardWidth - summaryRow.spacing
                                height: 118
                                radius: Theme.radiusSm
                                antialiasing: true
                                color: Theme.card
                                border.width: 1
                                border.color: Theme.stroke

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Theme.pad
                                    spacing: 6

                                    Text {
                                        text: "Monitores"
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                    }

                                    Repeater {
                                        model: root.monitorList
                                        delegate: Column {
                                            required property var modelData
                                            width: parent.width
                                            spacing: 1

                                            Text {
                                                text: (modelData && modelData.name ? modelData.name : "\u2014") + " \u00b7 " + root.monitorResolutionText(modelData) + " \u00b7 " + root.monitorScaleText(modelData)
                                                font.pixelSize: 12
                                                color: modelData && modelData.focused ? Theme.text : Theme.textDim
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: root.monitorWorkspaceText(modelData)
                                                font.pixelSize: 11
                                                color: Theme.textDim
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                        }
                                    }

                                    Text {
                                        visible: root.monitorList.length === 0
                                        text: "Monitor atual: " + Hyprland.monitorNameForScreen(root.screen)
                                        font.pixelSize: 12
                                        color: Theme.textDim
                                    }
                                }
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.gap

                            Repeater {
                                model: root.visibleWorkspaceList
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool realWorkspace: modelData && modelData.monitor !== undefined
                                    readonly property bool focusedWorkspace: realWorkspace ? Hyprland.isWorkspaceFocused(modelData) : !!modelData.focused
                                    readonly property bool activeWorkspace: realWorkspace ? Hyprland.isWorkspaceActive(modelData) : !!modelData.active
                                    readonly property bool urgentWorkspace: realWorkspace ? Hyprland.isWorkspaceUrgent(modelData) : false
                                    readonly property bool hasWindows: realWorkspace ? Hyprland.workspaceHasWindows(modelData) : (modelData && modelData.windows > 0)
                                    readonly property int windowCount: realWorkspace ? Hyprland.workspaceWindowCount(modelData) : (modelData && modelData.windows ? modelData.windows : 0)
                                    readonly property string workspaceLabel: realWorkspace ? Hyprland.workspaceLabel(modelData) : (modelData && modelData.label ? modelData.label : "\u2014")
                                    readonly property string monitorName: realWorkspace
                                        ? (modelData && modelData.monitor && modelData.monitor.name ? modelData.monitor.name : "\u2014")
                                        : (modelData && modelData.monitorName ? modelData.monitorName : "\u2014")
                                    width: 156
                                    height: 82
                                    radius: Theme.radiusSm
                                    antialiasing: true
                                    color: focusedWorkspace
                                        ? Theme.accentSoft
                                        : activeWorkspace
                                            ? Qt.darker(Theme.accentSoft, 1.03)
                                            : Theme.card
                                    border.width: urgentWorkspace || focusedWorkspace ? 2 : 1
                                    border.color: focusedWorkspace
                                        ? Theme.accent
                                        : urgentWorkspace
                                            ? Theme.accentActive
                                            : Theme.stroke

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 4

                                        Text {
                                            text: "Workspace " + parent.parent.workspaceLabel
                                            font.pixelSize: 15
                                            color: parent.parent.focusedWorkspace ? Theme.accentActive : Theme.text
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: "Monitor: " + parent.parent.monitorName
                                            font.pixelSize: 11
                                            color: Theme.textDim
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: parent.parent.windowCount + (parent.parent.windowCount === 1 ? " janela" : " janelas")
                                            font.pixelSize: 11
                                            color: parent.parent.hasWindows ? Theme.textDim : Theme.textFaint
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: root.workspaceStateText(parent.parent.modelData, parent.parent.realWorkspace)
                                            font.pixelSize: 11
                                            color: parent.parent.urgentWorkspace ? Theme.accentActive : Theme.textDim
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

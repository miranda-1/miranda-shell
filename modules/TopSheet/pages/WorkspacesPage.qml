import "../../../components"
import "../../../config"
import "../../../services"
import QtQuick

// Overview alt-tab por workspace: grade compacta e centralizada (posicionada
// pelo TopSheet). Cada card tem o mini-mapa real das janelas — clique no
// preview foca o workspace e fecha o painel; o X fecha as janelas do workspace
// (ação destrutiva → confirma no 2º toque).
Item {
    id: root

    property var screenRef

    signal requestClose()

    // todos os workspaces de todas as telas (não só os do monitor do shell)
    readonly property var workspaceList: Hyprland.workspaceList

    implicitHeight: content.implicitHeight

    Grid {
        id: content
        width: root.width
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        columns: Math.max(1, Math.min(root.workspaceList.length, 3))
        readonly property real cellW: (width - columnSpacing * (columns - 1)) / columns

        Repeater {
            model: root.workspaceList
            delegate: Rectangle {
                id: wsCard
                required property var modelData
                // conta pela lista real de toplevels (o IPC "windows" vem 0 em
                // workspace recém-criado) — alinha com o que o preview renderiza.
                readonly property int winCount: Math.max(Hyprland.workspaceToplevels(modelData).length,
                                                         Hyprland.workspaceWindowCount(modelData))
                readonly property bool focused: Hyprland.isWorkspaceFocused(modelData)
                readonly property bool active: Hyprland.isWorkspaceActive(modelData)
                readonly property bool activatable: Hyprland.canActivateWorkspace(modelData)
                property bool confirmingClose: false

                width: content.cellW
                implicitHeight: card.implicitHeight + Theme.pad * 2
                radius: Theme.radius
                antialiasing: true
                color: Theme.card
                border.width: 1
                border.color: focused ? Theme.accentActive
                              : active ? Theme.strokeStrong : Theme.stroke

                Column {
                    id: card
                    anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.pad }
                    spacing: Theme.gap

                    // ---- cabeçalho ----
                    Item {
                        width: parent.width
                        height: 28

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "WS " + Hyprland.workspaceLabel(wsCard.modelData)
                                font.pixelSize: Theme.fsBodyLg
                                font.bold: true
                                color: Theme.text
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: badgeText.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: wsCard.focused ? Theme.accentActive : Theme.accentTrack
                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: Hyprland.workspaceStatusLabel(wsCard.modelData)
                                    font.pixelSize: 10
                                    color: wsCard.focused ? Theme.textOnAccent : Theme.textDim
                                }
                            }
                        }

                        // botão fechar workspace (X) — confirma no 2º toque
                        Rectangle {
                            id: closeBtn
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            visible: wsCard.winCount > 0
                            height: 24
                            width: wsCard.confirmingClose ? confirmLabel.implicitWidth + 20 : 24
                            radius: 12
                            antialiasing: true
                            color: wsCard.confirmingClose ? Theme.accentActive
                                   : closeHover.hovered ? Theme.accentSoft : "transparent"
                            Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.tFast } }

                            Text {
                                anchors.centerIn: parent
                                visible: !wsCard.confirmingClose
                                text: ""
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.glyphSm
                                color: Theme.textDim
                            }
                            Text {
                                id: confirmLabel
                                anchors.centerIn: parent
                                visible: wsCard.confirmingClose
                                text: "Fechar tudo?"
                                font.pixelSize: Theme.fsCaption
                                color: Theme.textOnAccent
                            }

                            HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: {
                                    if (wsCard.confirmingClose) {
                                        Hyprland.closeWorkspace(wsCard.modelData);
                                        wsCard.confirmingClose = false;
                                    } else {
                                        wsCard.confirmingClose = true;
                                        confirmTimer.restart();
                                    }
                                }
                            }
                            Timer {
                                id: confirmTimer
                                interval: 2600
                                onTriggered: wsCard.confirmingClose = false
                            }
                        }
                    }

                    // ---- mini-mapa do workspace (clique foca) ----
                    Item {
                        width: parent.width
                        height: preview.implicitHeight
                        visible: wsCard.winCount > 0

                        WorkspacePreview {
                            id: preview
                            width: parent.width
                            workspace: wsCard.modelData
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSm
                            color: previewHover.hovered && wsCard.activatable ? Qt.rgba(0, 0, 0, 0.06) : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.tFast } }
                        }

                        HoverHandler {
                            id: previewHover
                            cursorShape: wsCard.activatable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            enabled: wsCard.activatable
                            onTapped: {
                                Hyprland.activateWorkspace(wsCard.modelData);
                                root.requestClose();
                            }
                        }
                    }

                    Text {
                        visible: wsCard.winCount === 0
                        text: "Workspace vazio."
                        font.pixelSize: Theme.fsBody
                        color: Theme.textDim
                    }
                }
            }
        }
    }
}

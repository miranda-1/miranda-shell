import "../../config"
import "../../components"
import "../../services"
import QtQuick

// Conteúdo da aba Dashboard (dados FAKE), inspirado no print #2.
// Cards internos são retângulos simples (sem sombra) — só o painel externo
// (EdgeTop) projeta sombra, para não aninhar layers e pesar a 240Hz.
// Glyphs Nerd Font via escapes \uXXXX (ASCII puro).
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    component Inner: Rectangle {
        color: Theme.card
        radius: Theme.radius
        antialiasing: true
    }

    Row {
        id: row
        spacing: Theme.gap

        // ---- coluna esquerda ----
        Column {
            spacing: Theme.gap

            Inner {
                width: 280; height: 124
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.pad
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""                 // sol
                        font.family: Theme.iconFont
                        font.pixelSize: 44
                        color: Theme.accent
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "15°C"; font.pixelSize: Theme.fsDisplay; color: Theme.text }
                        Text { text: "Clear"; font.pixelSize: 15; color: Theme.textDim }
                    }
                }
            }

            Inner {
                width: 280; height: 150
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clock.timeText
                        font.pixelSize: Theme.fsHero
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clock.dateText
                        font.pixelSize: 15
                        color: Theme.textDim
                    }
                }
            }
        }

        // ---- coluna do meio ----
        Column {
            spacing: Theme.gap

            Inner {
                width: 300; height: 124
                Column {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: Theme.pad + 4 }
                    spacing: 10
                    Row {
                        spacing: Theme.gap
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }  // arch
                        Text { text: "Arch Linux"; font.pixelSize: 15; color: Theme.text }
                    }
                    Row {
                        spacing: Theme.gap
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }  // wm
                        Text { text: "Hyprland"; font.pixelSize: 15; color: Theme.text }
                    }
                    Row {
                        spacing: Theme.gap
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }  // relógio
                        Text { text: "up 1 hour, 23 minutes"; font.pixelSize: 15; color: Theme.text }
                    }
                    // bateria real (read-only via UPower); some em máquinas sem bateria
                    Row {
                        spacing: Theme.gap
                        visible: Battery.available
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.accent }  // bateria
                        Text { text: Battery.statusText; font.pixelSize: 15; color: Theme.text }
                    }
                }
            }

            CalendarCard {
                width: 300
                cells: Clock.calendarCells
                highlight: Clock.currentDay
            }
        }

        // ---- coluna direita ----
        Column {
            spacing: Theme.gap

            Inner {
                width: 240; height: 174
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 60; height: 60; radius: 30
                        antialiasing: true
                        color: Theme.accentSoft
                        Text {
                            anchors.centerIn: parent
                            text: ""             // nota musical
                            font.family: Theme.iconFont
                            font.pixelSize: 26
                            color: Theme.accent
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Bad Apple!! feat. no…"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Alstroemeria Records"
                        font.pixelSize: Theme.fsBody
                        color: Theme.textDim
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.pad
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.textDim }  // prev
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: Theme.glyphMd; color: Theme.accent }   // play
                        Text { text: ""; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.textDim }  // next
                    }
                }
            }

            Inner {
                width: 240; height: 100
                Row {
                    anchors.centerIn: parent
                    spacing: 22
                    Repeater {
                        model: [
                            { v: 0.04, l: "CPU" },
                            { v: 0.42, l: "MEM" },
                            { v: 0.54, l: "TMP" }
                        ]
                        delegate: Column {
                            required property var modelData
                            spacing: 6
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 10
                                height: 52
                                radius: 5
                                antialiasing: true
                                color: Theme.accentTrack
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: parent.height * modelData.v
                                    radius: 5
                                    antialiasing: true
                                    color: Theme.accent
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.l
                                font.pixelSize: Theme.fsCaption
                                color: Theme.textDim
                            }
                        }
                    }
                }
            }
        }
    }
}

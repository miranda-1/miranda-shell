import "../../../components"
import "../../../config"
import "../../../services"
import QtQuick

Item {
    id: root

    implicitHeight: content.implicitHeight

    Column {
        id: content
        width: root.width
        spacing: Theme.pad

        Repeater {
            model: Keybinds.groups

            delegate: Column {
                required property var modelData

                width: content.width
                spacing: Theme.gap

                // título do tópico
                Text {
                    text: parent.modelData.title
                    font.pixelSize: Theme.fsLabel
                    font.bold: true
                    color: Theme.textDim
                }

                Repeater {
                    model: parent.modelData.items

                    delegate: Rectangle {
                        required property var modelData

                        width: content.width
                        height: 44
                        radius: Theme.radiusSm
                        color: Theme.card
                        border.width: 1
                        border.color: Theme.stroke
                        antialiasing: true

                        Rectangle {
                            id: comboPill
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            width: comboText.implicitWidth + 18
                            height: 26
                            radius: 8
                            color: Theme.accentSoft
                            antialiasing: true

                            Text {
                                id: comboText
                                anchors.centerIn: parent
                                text: parent.parent.modelData.combo
                                font.pixelSize: Theme.fsCaption
                                font.bold: true
                                color: Theme.accentActive
                            }
                        }

                        Text {
                            anchors.left: comboPill.right
                            anchors.leftMargin: Theme.pad
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.desc
                            font.pixelSize: Theme.fsBody
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Text {
            visible: Keybinds.groups.length === 0
            width: parent.width
            text: "Não foi possível ler ~/.config/hypr/keybindings.conf."
            font.pixelSize: Theme.fsBody
            color: Theme.textDim
            wrapMode: Text.Wrap
        }
    }
}

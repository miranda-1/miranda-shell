import "../config"
import QtQuick

// Mini-calendário do mês corrente. Recebe `cells` (grade real do Clock) e marca
// o dia `highlight` em círculo clay. Semana começando na segunda-feira.
Rectangle {
    id: root

    property int highlight: -1
    // Lista de células do mês: cada item { day: int (0 = vazio), empty: bool }.
    // Vem do Clock; semana começa na segunda (alinhado ao cabeçalho Mon..Sun).
    property var cells: []

    color: Theme.card
    radius: Theme.radius
    antialiasing: true
    implicitWidth: grid.implicitWidth + Theme.pad * 2
    implicitHeight: header.height + grid.implicitHeight + Theme.pad * 2 + Theme.gap

    Column {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.pad }
        spacing: Theme.gap

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                delegate: Text {
                    required property var modelData
                    width: 34
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textDim
                }
            }
        }
    }

    Grid {
        id: grid
        anchors { top: header.bottom; topMargin: Theme.gap; horizontalCenter: parent.horizontalCenter }
        columns: 7
        rowSpacing: 2
        columnSpacing: 0
        Repeater {
            model: root.cells
            delegate: Item {
                required property var modelData
                width: 34
                height: 28
                readonly property bool isHi: !modelData.empty && modelData.day === root.highlight

                Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    antialiasing: true
                    visible: parent.isHi
                    color: Theme.accentActive
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData.empty ? "" : modelData.day
                    font.pixelSize: 13
                    color: parent.isHi ? Theme.textOnAccent : Theme.text
                }
            }
        }
    }
}

import "../config"
import QtQuick

// Anel de progresso circular (Performance). `value` em 0..1. Dados FAKE.
Item {
    id: root

    property real value: 0.4
    property string big: ""
    property string sub: ""

    implicitWidth: 150
    implicitHeight: 150

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2;
            const r = Math.min(width, height) / 2 - Theme.ringWidth;
            const start = -Math.PI / 2;
            ctx.lineWidth = Theme.ringWidth;
            ctx.lineCap = "round";
            // trilha
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.strokeStyle = Theme.accentTrack;
            ctx.stroke();
            // valor
            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + root.value * 2 * Math.PI);
            ctx.strokeStyle = Theme.accent;
            ctx.stroke();
        }
        Component.onCompleted: requestPaint()
    }

    onValueChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Column {
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.big
            font.pixelSize: 26
            color: Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.sub
            font.pixelSize: Theme.fsBody
            color: Theme.textDim
        }
    }
}

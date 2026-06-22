import "../../../components"
import "../../../config"
import "../../../services"
import QtQuick

Item {
    id: root

    implicitHeight: content.implicitHeight

    // seções expansíveis (uma por vez)
    property bool wifiExpanded: false
    property bool btExpanded: false
    property bool audioExpanded: false

    // rede protegida aguardando senha (identificada pelo nome) + senha digitada
    property string pwTargetName: ""
    property string pwText: ""

    // glyphs Nerd Font (BMP) — escapes explícitos
    readonly property string glyphWifi: ""
    readonly property string glyphBluetooth: ""
    readonly property string glyphBolt: ""
    readonly property string glyphBattery: ""
    readonly property string glyphVolume: ""
    readonly property string glyphVolumeMuted: ""
    readonly property string glyphSun: ""
    readonly property string glyphLock: ""
    readonly property string glyphCheck: ""
    readonly property string glyphEthernet: "󰨾"

    // escaneia redes só enquanto esta página existe
    Component.onCompleted: Network.setScanning(true)
    Component.onDestruction: {
        Network.setScanning(false);
        Bluez.setDiscovering(false);
    }

    // procura dispositivos BT próximos só enquanto o painel Bluetooth está aberto
    onBtExpandedChanged: Bluez.setDiscovering(root.btExpanded)

    function signalPercent(net) {
        const s = (net && net.signalStrength) || 0;
        return s > 1 ? Math.round(s) : Math.round(s * 100);
    }

    Column {
        id: content
        width: root.width
        spacing: Theme.pad

        // ---- linha de toggles funcionais ----
        Row {
            width: parent.width
            spacing: Theme.gap

            QuickToggle {
                width: (parent.width - Theme.gap * 3) / 4
                glyph: root.glyphWifi
                title: "Rede"
                subtitle: Network.statusText + (Network.hasWifiDevice ? " • toque para ver redes" : "")
                checked: Network.wifiEnabled
                live: Network.available
                interactive: Network.available
                onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
                onActivated: {
                    root.wifiExpanded = !root.wifiExpanded;
                    if (root.wifiExpanded) {
                        root.btExpanded = false;
                        root.audioExpanded = false;
                    }
                }
            }

            QuickToggle {
                width: (parent.width - Theme.gap * 3) / 4
                glyph: root.glyphBluetooth
                title: "Bluetooth"
                subtitle: Bluez.statusText + (Bluez.available ? " • toque para ver dispositivos" : "")
                checked: Bluez.enabled
                live: Bluez.available
                interactive: Bluez.available
                onToggled: Bluez.setEnabled(!Bluez.enabled)
                onActivated: {
                    root.btExpanded = !root.btExpanded;
                    if (root.btExpanded) {
                        root.wifiExpanded = false;
                        root.audioExpanded = false;
                    }
                }
            }

            // Perfil de energia — 3 estados (toque num segmento para escolher)
            Rectangle {
                width: (parent.width - Theme.gap * 3) / 4
                implicitHeight: 92
                radius: Theme.radius
                color: Theme.card
                border.width: 1
                border.color: Theme.stroke
                antialiasing: true

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: Theme.pad

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            antialiasing: true
                            color: Theme.accentSoft

                            Text {
                                anchors.centerIn: parent
                                text: root.glyphBolt
                                font.family: Theme.iconFont
                                font.pixelSize: 17
                                color: Theme.accentActive
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 52
                            spacing: 3

                            Text {
                                text: "Perfil"
                                font.pixelSize: Theme.fsLabel
                                color: Theme.text
                            }

                            Text {
                                width: parent.width
                                text: Battery.profileText
                                font.pixelSize: Theme.fsBody
                                color: Theme.textDim
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Economia · Equilibrado · Performance
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                required property int index

                                width: (parent.width - 12) / 3
                                height: 12
                                radius: 6
                                antialiasing: true
                                color: Battery.profileIndex === index ? Theme.accentActive : Theme.accentTrack

                                Behavior on color { ColorAnimation { duration: Theme.tFast } }

                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: Battery.setProfileIndex(index) }
                            }
                        }
                    }
                }
            }

            // Bateria — apenas informativo (não é botão)
            Rectangle {
                width: (parent.width - Theme.gap * 3) / 4
                implicitHeight: 92
                radius: Theme.radius
                color: Theme.card
                border.width: 1
                border.color: Theme.stroke
                antialiasing: true

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: Theme.pad

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        antialiasing: true
                        color: Battery.available ? Theme.accentSoft : Theme.accentTrack

                        Text {
                            anchors.centerIn: parent
                            text: root.glyphBattery
                            font.family: Theme.iconFont
                            font.pixelSize: 17
                            color: Battery.available ? Theme.accentActive : Theme.textDim
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 52
                        spacing: 3

                        Text {
                            width: parent.width
                            text: Battery.available ? Battery.percentText : "Bateria"
                            font.pixelSize: Theme.fsLabel
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Battery.available
                                ? (Battery.charging ? "Carregando"
                                    : (Battery.timeText.length > 0 ? Battery.timeText + " restante" : Battery.statusText))
                                : "Sem bateria exposta"
                            font.pixelSize: Theme.fsBody
                            color: Theme.textDim
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // ---- redes Wi-Fi visíveis ----
        Rectangle {
            visible: root.wifiExpanded
            width: parent.width
            implicitHeight: wifiList.implicitHeight + Theme.pad * 2
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.stroke
            antialiasing: true
            clip: true

            Column {
                id: wifiList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.pad
                spacing: Theme.gap

                // ---- status do cabo de rede (Ethernet) ----
                Rectangle {
                    visible: Network.hasWiredDevice
                    width: parent.width
                    height: 52
                    radius: Theme.radiusSm
                    antialiasing: true
                    color: Network.wiredConnected ? Theme.accentSoft : Theme.accentTrack
                    border.width: 1
                    border.color: Network.wiredConnected ? Theme.strokeStrong : Theme.stroke

                    Text {
                        id: ethGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.pad
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyphEthernet
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Network.wiredConnected ? Theme.accentActive : Theme.textDim
                    }

                    Text {
                        id: ethBadge
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.pad
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.wiredConnected ? root.glyphCheck + "  conectado" : "sem cabo"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.fsCaption
                        color: Network.wiredConnected ? Theme.accentActive : Theme.textDim
                    }

                    Column {
                        anchors.left: ethGlyph.right
                        anchors.leftMargin: Theme.pad
                        anchors.right: ethBadge.left
                        anchors.rightMargin: Theme.pad
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: "Cabo de rede"
                            font.pixelSize: Theme.fsBodyLg
                            color: Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Network.wiredConnected
                                ? "Conectado" + (Network.wiredName.length > 0 ? " • " + Network.wiredName : "")
                                : "Desconectado — conecte o cabo"
                            font.pixelSize: Theme.fsCaption
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: wifiTitle.implicitHeight

                    Text {
                        id: wifiTitle
                        anchors.left: parent.left
                        text: "Redes Wi-Fi"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.textDim
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "toque conecta em rede salva"
                        font.pixelSize: Theme.fsCaption
                        color: Theme.textFaint
                    }
                }

                Repeater {
                    model: Network.wifiNetworks.slice(0, 8)

                    delegate: Rectangle {
                        id: netRow

                        required property var modelData

                        readonly property string netName: netRow.modelData.name || ""
                        readonly property bool isConnected: netRow.modelData.connected
                        readonly property bool wantsPw: Network.needsPassword(netRow.modelData)
                        readonly property bool showPw: root.pwTargetName === netRow.netName
                            && netRow.wantsPw && !netRow.isConnected

                        width: parent.width
                        height: rowCol.height
                        radius: Theme.radiusSm
                        antialiasing: true
                        color: netRow.isConnected ? Theme.accentSoft
                             : netHover.hovered ? Theme.accentSoft
                             : Theme.accentTrack
                        border.width: 1
                        border.color: netRow.isConnected ? Theme.strokeStrong : Theme.stroke

                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        Column {
                            id: rowCol
                            width: parent.width

                            // linha principal (clicável)
                            Item {
                                width: parent.width
                                height: 52

                                HoverHandler {
                                    id: netHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: {
                                        if (netRow.isConnected) {
                                            Network.disconnectNetwork(netRow.modelData);
                                        } else if (netRow.wantsPw) {
                                            root.pwTargetName = (root.pwTargetName === netRow.netName) ? "" : netRow.netName;
                                            root.pwText = "";
                                        } else {
                                            Network.connectToNetwork(netRow.modelData);
                                        }
                                    }
                                }

                                Text {
                                    id: netGlyph
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.glyphWifi
                                    font.family: Theme.iconFont
                                    font.pixelSize: 15
                                    color: Theme.accent
                                    opacity: 0.35 + 0.65 * Math.min(1, root.signalPercent(netRow.modelData) / 100)
                                }

                                Text {
                                    id: netBadge
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: netRow.isConnected
                                        ? root.glyphCheck + "  conectada"
                                        : root.signalPercent(netRow.modelData) + "%"
                                            + (Network.isSecured(netRow.modelData) ? "  " + root.glyphLock : "")
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.fsCaption
                                    color: netRow.isConnected ? Theme.accentActive : Theme.textDim
                                }

                                Column {
                                    anchors.left: netGlyph.right
                                    anchors.leftMargin: Theme.pad
                                    anchors.right: netBadge.left
                                    anchors.rightMargin: Theme.pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: netRow.netName || "Rede oculta"
                                        font.pixelSize: Theme.fsBodyLg
                                        color: Theme.text
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: netRow.isConnected ? "Conectada — toque para desconectar"
                                            : netRow.modelData.known ? "Salva — toque para conectar"
                                            : netRow.wantsPw ? (netRow.showPw ? "Digite a senha abaixo" : "Protegida — toque para inserir a senha")
                                            : "Aberta — toque para conectar"
                                        font.pixelSize: Theme.fsCaption
                                        color: Theme.textDim
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // campo de senha (só para rede protegida ainda não salva)
                            Item {
                                width: parent.width
                                height: netRow.showPw ? 44 : 0
                                visible: netRow.showPw
                                clip: true

                                Rectangle {
                                    id: pwBox
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.pad
                                    anchors.right: connectBtn.left
                                    anchors.rightMargin: Theme.gap
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 32
                                    radius: Theme.radiusSm
                                    color: Theme.card
                                    border.width: 1
                                    border.color: Theme.stroke

                                    TextInput {
                                        id: pwInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        font.pixelSize: Theme.fsBody
                                        color: Theme.text
                                        clip: true
                                        focus: netRow.showPw
                                        text: root.pwText
                                        onTextChanged: root.pwText = text
                                        onAccepted: {
                                            if (Network.connectWithPassword(netRow.modelData, root.pwText)) {
                                                root.pwTargetName = "";
                                                root.pwText = "";
                                            }
                                        }

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            visible: pwInput.text.length === 0
                                            text: "Senha da rede"
                                            font.pixelSize: Theme.fsBody
                                            color: Theme.textFaint
                                        }
                                    }
                                }

                                Rectangle {
                                    id: connectBtn
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.pad
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 96
                                    height: 32
                                    radius: Theme.radiusSm
                                    color: connectHover.hovered ? Theme.accentActive : Theme.accent

                                    Behavior on color { ColorAnimation { duration: Theme.tFast } }

                                    HoverHandler { id: connectHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            if (Network.connectWithPassword(netRow.modelData, root.pwText)) {
                                                root.pwTargetName = "";
                                                root.pwText = "";
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Conectar"
                                        font.pixelSize: Theme.fsBody
                                        color: Theme.textOnAccent
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: Network.wifiNetworks.length === 0
                    width: parent.width
                    text: !Network.hasWifiDevice ? "Sem adaptador Wi-Fi nesta máquina."
                        : !Network.wifiEnabled ? "Wi-Fi desligado — use o switch acima."
                        : "Procurando redes…"
                    font.pixelSize: Theme.fsBodyLg
                    color: Theme.textDim
                    wrapMode: Text.Wrap
                }
            }
        }

        // ---- dispositivos Bluetooth pareados ----
        Rectangle {
            visible: root.btExpanded
            width: parent.width
            implicitHeight: btList.implicitHeight + Theme.pad * 2
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.stroke
            antialiasing: true
            clip: true

            Column {
                id: btList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.pad
                spacing: Theme.gap

                Item {
                    width: parent.width
                    height: btTitle.implicitHeight

                    Text {
                        id: btTitle
                        anchors.left: parent.left
                        text: "Dispositivos pareados"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.textDim
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "toque conecta/desconecta"
                        font.pixelSize: Theme.fsCaption
                        color: Theme.textFaint
                    }
                }

                Repeater {
                    model: Bluez.pairedDevices

                    delegate: Rectangle {
                        id: btRow

                        required property var modelData

                        width: parent.width
                        height: 52
                        radius: Theme.radiusSm
                        antialiasing: true
                        color: btRow.modelData.connected ? Theme.accentSoft
                             : btHover.hovered ? Theme.accentSoft
                             : Theme.accentTrack
                        border.width: 1
                        border.color: btRow.modelData.connected ? Theme.strokeStrong : Theme.stroke

                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        HoverHandler {
                            id: btHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: Bluez.toggleDevice(btRow.modelData)
                        }

                        Text {
                            id: btGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.glyphBluetooth
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                            color: btRow.modelData.connected ? Theme.accentActive : Theme.textDim
                        }

                        Text {
                            id: btBadge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: btRow.modelData.connected
                                ? root.glyphCheck + "  conectado"
                                : "pareado"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fsCaption
                            color: btRow.modelData.connected ? Theme.accentActive : Theme.textDim
                        }

                        Column {
                            anchors.left: btGlyph.right
                            anchors.leftMargin: Theme.pad
                            anchors.right: btBadge.left
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: btRow.modelData.name || "Dispositivo"
                                font.pixelSize: Theme.fsBodyLg
                                color: Theme.text
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: btRow.modelData.batteryAvailable
                                    ? "Bateria " + Math.round(btRow.modelData.battery * 100) + "%"
                                    : (btRow.modelData.connected ? "Conectado" : "Toque para conectar")
                                font.pixelSize: Theme.fsCaption
                                color: Theme.textDim
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: Bluez.pairedDevices.length === 0
                    width: parent.width
                    text: !Bluez.available ? "Sem adaptador Bluetooth nesta máquina."
                        : !Bluez.enabled ? "Bluetooth desligado — use o switch acima."
                        : "Nenhum dispositivo pareado ainda. Use a lista abaixo para parear."
                    font.pixelSize: Theme.fsBodyLg
                    color: Theme.textDim
                    wrapMode: Text.Wrap
                }

                // ---- dispositivos próximos para parear ----
                Item {
                    visible: Bluez.enabled
                    width: parent.width
                    height: discTitle.implicitHeight

                    Text {
                        id: discTitle
                        anchors.left: parent.left
                        text: "Disponíveis para parear"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.textDim
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Bluez.discovering ? "procurando…" : ""
                        font.pixelSize: Theme.fsCaption
                        color: Theme.textFaint
                    }
                }

                Repeater {
                    model: Bluez.enabled ? Bluez.discoveredDevices.slice(0, 8) : []

                    delegate: Rectangle {
                        id: discRow

                        required property var modelData

                        width: parent.width
                        height: 52
                        radius: Theme.radiusSm
                        antialiasing: true
                        color: discHover.hovered ? Theme.accentSoft : Theme.accentTrack
                        border.width: 1
                        border.color: Theme.stroke

                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        HoverHandler {
                            id: discHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            enabled: !discRow.modelData.pairing
                            onTapped: Bluez.pairDevice(discRow.modelData)
                        }

                        Text {
                            id: discGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.glyphBluetooth
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                            color: Theme.textDim
                        }

                        Text {
                            id: discBadge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: discRow.modelData.pairing ? "pareando…" : "parear"
                            font.pixelSize: Theme.fsCaption
                            color: discRow.modelData.pairing ? Theme.accentActive : Theme.textDim
                        }

                        Column {
                            anchors.left: discGlyph.right
                            anchors.leftMargin: Theme.pad
                            anchors.right: discBadge.left
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: discRow.modelData.name || discRow.modelData.deviceName
                                    || discRow.modelData.address || "Dispositivo"
                                font.pixelSize: Theme.fsBodyLg
                                color: Theme.text
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: discRow.modelData.pairing ? "Pareando…" : "Toque para parear"
                                font.pixelSize: Theme.fsCaption
                                color: Theme.textDim
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Text {
                    visible: Bluez.enabled && Bluez.discoveredDevices.length === 0
                    width: parent.width
                    text: Bluez.discovering ? "Procurando dispositivos próximos…"
                        : "Deixe o aparelho em modo de pareamento e aguarde."
                    font.pixelSize: Theme.fsBody
                    color: Theme.textFaint
                    wrapMode: Text.Wrap
                }
            }
        }

        // ---- sliders ----
        Row {
            width: parent.width
            spacing: Theme.gap

            ControlSlider {
                width: (parent.width - Theme.gap) / 2
                glyph: Audio.muted ? root.glyphVolumeMuted : root.glyphVolume
                label: "Volume"
                value: Math.min(1, Audio.volume)
                live: Audio.available && !Audio.muted
                interactive: Audio.available
                detail: !Audio.available ? "Pipewire indisponível nesta sessão."
                    : Audio.muted ? "Mudo — toque no ícone do som para reativar."
                    : Audio.hasMultipleSinks ? "Saindo por: " + Audio.deviceName
                    : Audio.deviceName
                expandable: Audio.available && Audio.hasMultipleSinks && !Audio.muted
                muteEnabled: Audio.available
                muted: Audio.muted
                onMoved: (newValue) => Audio.setVolume(newValue)
                onBadgeClicked: Audio.toggleMute()
                onMuteToggled: Audio.toggleMute()
                onDetailClicked: {
                    root.audioExpanded = !root.audioExpanded;
                    if (root.audioExpanded) {
                        root.wifiExpanded = false;
                        root.btExpanded = false;
                    }
                }
            }

            ControlSlider {
                width: (parent.width - Theme.gap) / 2
                glyph: root.glyphSun
                label: "Brilho"
                value: Brightness.available ? Brightness.value : 0.74
                live: Brightness.available
                interactive: Brightness.available
                detail: Brightness.available
                    ? "Tela interna do notebook."
                    : "Sem backlight interno detectado nesta sessão."
                onMoved: (newValue) => Brightness.setPercent(newValue)
            }
        }

        // ---- saídas de áudio (para onde o som sai) ----
        Rectangle {
            visible: root.audioExpanded
            width: parent.width
            implicitHeight: audioList.implicitHeight + Theme.pad * 2
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.stroke
            antialiasing: true
            clip: true

            Column {
                id: audioList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.pad
                spacing: Theme.gap

                Item {
                    width: parent.width
                    height: audioTitle.implicitHeight

                    Text {
                        id: audioTitle
                        anchors.left: parent.left
                        text: "Saída de som"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.textDim
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "toque para mudar"
                        font.pixelSize: Theme.fsCaption
                        color: Theme.textFaint
                    }
                }

                Repeater {
                    model: Audio.sinks

                    delegate: Rectangle {
                        id: sinkRow

                        required property var modelData

                        readonly property bool isCurrent: Audio.isDefaultSink(sinkRow.modelData)

                        width: parent.width
                        height: 52
                        radius: Theme.radiusSm
                        antialiasing: true
                        color: sinkRow.isCurrent ? Theme.accentSoft
                             : sinkHover.hovered ? Theme.accentSoft
                             : Theme.accentTrack
                        border.width: 1
                        border.color: sinkRow.isCurrent ? Theme.strokeStrong : Theme.stroke

                        Behavior on color { ColorAnimation { duration: Theme.tFast } }

                        HoverHandler {
                            id: sinkHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: Audio.setDefaultSink(sinkRow.modelData)
                        }

                        Text {
                            id: sinkGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.glyphVolume
                            font.family: Theme.iconFont
                            font.pixelSize: 15
                            color: sinkRow.isCurrent ? Theme.accentActive : Theme.textDim
                        }

                        Text {
                            id: sinkBadge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: sinkRow.isCurrent ? root.glyphCheck + "  atual" : "usar"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.fsCaption
                            color: sinkRow.isCurrent ? Theme.accentActive : Theme.textDim
                        }

                        Text {
                            anchors.left: sinkGlyph.right
                            anchors.leftMargin: Theme.pad
                            anchors.right: sinkBadge.left
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: Audio.sinkLabel(sinkRow.modelData)
                            font.pixelSize: Theme.fsBodyLg
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    visible: Audio.sinks.length === 0
                    width: parent.width
                    text: "Nenhuma saída de áudio detectada."
                    font.pixelSize: Theme.fsBodyLg
                    color: Theme.textDim
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}

import "../../../components"
import "../../../config"
import "../../../services"
import Quickshell
import QtQuick

Item {
    id: root

    implicitHeight: content.implicitHeight

    // glyph Nerd Font do Spotify (U+F04C7) — preenchido via script (PUA some no editor)
    property string glyphSpotify: "󰓇"

    // abre o app do Spotify pela DesktopEntry (execução segura, sem shell eval)
    function openSpotify() {
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i];
            const hay = ((e.name || "") + " " + (e.id || "") + " " + (e.execString || "")).toLowerCase();
            if (hay.indexOf("spotify") >= 0) {
                e.execute();
                return true;
            }
        }
        return false;
    }

    Column {
        id: content
        width: root.width
        spacing: Theme.pad

        Rectangle {
            width: parent.width
            implicitHeight: 288
            radius: Theme.radius
            color: Theme.card
            border.width: 1
            border.color: Theme.stroke
            antialiasing: true

            Row {
                anchors.fill: parent
                anchors.margins: Theme.pad + 4
                spacing: Theme.pad + 4

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 180
                    height: 180
                    radius: 90
                    antialiasing: true
                    color: Theme.accentSoft

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: Theme.iconFont
                        font.pixelSize: 54
                        color: Theme.accentActive
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 232
                    spacing: 10

                    MarqueeText {
                        text: Media.displayTitle
                        maxWidth: parent.width
                        pixelSize: 26
                        bold: true
                        color: Theme.text
                    }

                    MarqueeText {
                        text: Media.displaySubtitle
                        maxWidth: parent.width
                        pixelSize: Theme.fsLabel
                        color: Theme.textDim
                    }

                    Row {
                        spacing: 8

                        Rectangle {
                            width: statusText.implicitWidth + 18
                            height: 28
                            radius: 14
                            color: Media.isPlaying ? Theme.accentSoft : Theme.accentTrack

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: Media.statusText
                                font.pixelSize: 11
                                color: Media.isPlaying ? Theme.accentActive : Theme.textDim
                            }
                        }

                        Rectangle {
                            visible: Media.available
                            width: playerText.implicitWidth + 18
                            height: 28
                            radius: 14
                            color: Theme.accentTrack

                            Text {
                                id: playerText
                                anchors.centerIn: parent
                                text: Media.activePlayerName
                                font.pixelSize: 11
                                color: Theme.textDim
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 5
                        color: Theme.accentTrack
                        antialiasing: true

                        Rectangle {
                            width: Math.max(height, parent.width * Media.progress)
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accentActive
                            antialiasing: true
                        }
                    }

                    Item {
                        width: parent.width
                        height: posText.implicitHeight

                        Text {
                            id: posText
                            anchors.left: parent.left
                            text: Media.positionText
                            font.pixelSize: Theme.fsBody
                            color: Theme.textDim
                        }

                        Text {
                            anchors.right: parent.right
                            text: Media.lengthText
                            font.pixelSize: Theme.fsBody
                            color: Theme.textDim
                        }
                    }

                    Row {
                        spacing: Theme.pad + 10

                        Repeater {
                            model: [
                                { glyph: "", enabled: Media.canPrevious, action: function() { Media.previous(); } },
                                { glyph: Media.isPlaying ? "" : "", enabled: Media.canPlayPause, action: function() { Media.playPause(); } },
                                { glyph: "", enabled: Media.canNext, action: function() { Media.next(); } }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: modelData.glyph === (Media.isPlaying ? "" : "") ? 54 : 46
                                height: width
                                radius: width / 2
                                color: modelData.enabled ? Theme.cardHover : Theme.accentTrack
                                opacity: modelData.enabled ? 1 : 0.5
                                antialiasing: true

                                HoverHandler {
                                    id: mediaHover
                                    enabled: modelData.enabled
                                    cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    enabled: modelData.enabled
                                    onTapped: modelData.action()
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    font.family: Theme.iconFont
                                    font.pixelSize: modelData.glyph === (Media.isPlaying ? "" : "") ? 22 : 18
                                    color: modelData.enabled ? Theme.accentActive : Theme.textDim
                                }
                            }
                        }
                    }
                }
            }
        }

        // atalho rápido para abrir o app do Spotify
        Rectangle {
            width: parent.width
            implicitHeight: 72
            radius: Theme.radius
            color: spotifyHover.hovered ? Theme.cardHover : Theme.card
            border.width: 1
            border.color: Theme.stroke
            antialiasing: true

            Behavior on color { ColorAnimation { duration: Theme.tFast } }

            HoverHandler {
                id: spotifyHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: root.openSpotify()
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.pad + 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.pad

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    radius: 22
                    antialiasing: true
                    color: Theme.accentSoft

                    Text {
                        anchors.centerIn: parent
                        text: root.glyphSpotify
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                        color: Theme.accentActive
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Abrir Spotify"
                        font.pixelSize: Theme.fsLabel
                        color: Theme.text
                    }

                    Text {
                        text: "Inicia o aplicativo do Spotify"
                        font.pixelSize: Theme.fsBody
                        color: Theme.textDim
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: Theme.pad + 4
                anchors.verticalCenter: parent.verticalCenter
                width: openLabel.implicitWidth + 24
                height: 30
                radius: 15
                color: spotifyHover.hovered ? Theme.accentActive : Theme.accentTrack

                Behavior on color { ColorAnimation { duration: Theme.tFast } }

                Text {
                    id: openLabel
                    anchors.centerIn: parent
                    text: "Abrir"
                    font.pixelSize: Theme.fsBody
                    color: spotifyHover.hovered ? Theme.textOnAccent : Theme.textDim
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.gap

            MetricCard {
                width: (parent.width - Theme.gap * 2) / 3
                glyph: "󰓇"
                title: "Fonte"
                value: Media.available ? Media.activePlayerName : "Nenhuma"
                subtitle: Media.available ? Media.playbackStatus : "Sem sessão MPRIS elegível"
            }

            MetricCard {
                width: (parent.width - Theme.gap * 2) / 3
                glyph: ""
                title: "Players"
                value: Media.detectedPlayerCount + ""
                subtitle: Media.playerCount + " com estado ativo ou pausado"
            }

            MetricCard {
                width: (parent.width - Theme.gap * 2) / 3
                glyph: ""
                title: "Fallback"
                value: Media.available ? "Pronto" : "Aguardando"
                subtitle: "A UI não quebra quando o player omite título ou artista."
            }
        }
    }
}

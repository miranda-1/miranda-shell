import "../../components"
import "../../config"
import "../../services"
import "pages"
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var modelData
    required property bool open
    required property string currentPage

    signal requestClose()

    screen: modelData
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    implicitHeight: root.screenHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open && root.currentPage === "search"
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    readonly property real screenWidth: root.screen && root.screen.width ? root.screen.width : 1440
    readonly property real screenHeight: root.screen && root.screen.height ? root.screen.height : 900
    readonly property real interactiveLeft: Theme.barW
    readonly property real availableWidth: Math.max(720, root.screenWidth - root.interactiveLeft - 48)
    readonly property real panelWidth: Math.min(root.availableWidth, 1180)
    readonly property real panelHeight: Math.min(Math.max(root.screenHeight * 0.57, 480), 720)
    readonly property real topOffset: 18
    readonly property bool panelVisible: root.open || sheet.opacity > 0.01
    readonly property string pageGlyph: root.metaForPage(root.currentPage).glyph
    readonly property string pageTitle: root.metaForPage(root.currentPage).title
    readonly property string pageSubtitle: root.metaForPage(root.currentPage).subtitle
    readonly property var headerPills: root.pillsForPage(root.currentPage)

    function metaForPage(pageId) {
        switch (pageId) {
        case "search":
            return { glyph: "", title: "Busca e Launcher", subtitle: "Procure apps, atalhos e pontos de entrada sem sair da superfície principal." };
        case "calendar":
            return { glyph: "", title: "Calendário", subtitle: "Hora, data e visão mensal num painel dedicado e estável." };
        case "controls":
            return { glyph: "", title: "Controles", subtitle: "Rede, energia e placeholders visuais para ajustes futuros seguros." };
        case "media":
            return { glyph: "", title: "Mídia", subtitle: "Estado MPRIS real, progresso e controles já aprovados centralizados aqui." };
        case "workspaces":
            return { glyph: "", title: "Workspaces", subtitle: "Resumo real do Hyprland por tela com troca segura de workspace." };
        case "system":
            return { glyph: "", title: "Sistema", subtitle: "Sessão, uptime, bateria e leituras do ambiente atual sem polling externo." };
        case "profile":
            return { glyph: "", title: "Perfil e Energia", subtitle: "Identidade da sessão e ações futuras expostas apenas como placeholders." };
        case "dashboard":
        default:
            return { glyph: "", title: "Dashboard", subtitle: "Resumo vivo da shell com janela ativa, rede, bateria, mídia e contexto da tela." };
        }
    }

    function pillsForPage(pageId) {
        const pills = [
            { glyph: "", text: Hyprland.monitorNameForScreen(root.screen), active: true }
        ];

        switch (pageId) {
        case "media":
            pills.push({ glyph: "", text: Media.available ? Media.statusText : "Sem player", active: Media.available });
            if (Media.available)
                pills.push({ glyph: "", text: Media.activePlayerName, active: false });
            break;
        case "workspaces":
            pills.push({ glyph: "", text: "WS " + Hyprland.activeWorkspaceLabel, active: true });
            pills.push({ glyph: "", text: Hyprland.activeWindowClass, active: false });
            break;
        case "controls":
            pills.push({ glyph: "", text: Network.statusText, active: Network.connected });
            if (Battery.available)
                pills.push({ glyph: "", text: Battery.statusText, active: Battery.onBattery });
            break;
        case "calendar":
            pills.push({ glyph: "", text: Clock.dateText, active: false });
            break;
        case "search":
            pills.push({ glyph: "", text: "Launcher embutido", active: true });
            break;
        case "system":
        case "profile":
            pills.push({ glyph: "", text: System.osName || "Linux", active: false });
            if (Battery.available)
                pills.push({ glyph: "", text: Battery.profileText, active: true });
            break;
        default:
            pills.push({ glyph: "", text: Network.statusText, active: Network.connected });
            pills.push({ glyph: "", text: Hyprland.activeWindowClass, active: false });
            if (Battery.available)
                pills.push({ glyph: "", text: Battery.statusText, active: Battery.onBattery });
            break;
        }

        return pills;
    }

    mask: Region {
        x: root.panelVisible ? Math.round(root.interactiveLeft) : 0
        y: 0
        width: root.panelVisible ? Math.max(0, Math.ceil(root.width - root.interactiveLeft)) : 0
        height: root.panelVisible ? root.height : 0
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.panelVisible
        onClicked: (mouse) => {
            const insidePanel = mouse.x >= sheet.x
                && mouse.x <= sheet.x + sheet.width
                && mouse.y >= sheet.y
                && mouse.y <= sheet.y + sheet.height;

            if (!insidePanel)
                root.requestClose();
        }
    }

    Card {
        id: sheet
        x: root.interactiveLeft + Math.max(24, (root.width - root.interactiveLeft - root.panelWidth) / 2)
        y: root.open ? root.topOffset : -root.panelHeight - 40
        width: root.panelWidth
        height: root.panelHeight
        radius: Theme.radiusLg
        color: Qt.rgba(Theme.surfaceStrong.r, Theme.surfaceStrong.g, Theme.surfaceStrong.b, 0.995)
        border.color: Theme.strokeStrong
        opacity: root.open ? 1 : 0
        clip: true
        visible: root.panelVisible

        Behavior on x { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutExpo } }
        Behavior on y { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.pad + 2
            spacing: Theme.pad

            TopSheetHeader {
                width: parent.width
                glyph: root.pageGlyph
                title: root.pageTitle
                subtitle: root.pageSubtitle
                pills: root.headerPills
                showCloseButton: true
                onCloseRequested: root.requestClose()
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.stroke
            }

            Flickable {
                id: scroll
                width: parent.width
                height: parent.height - 105
                clip: true
                contentWidth: width
                contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: pageLoader
                    width: scroll.width
                    sourceComponent: root.currentPage === "search" ? searchPage
                        : root.currentPage === "calendar" ? calendarPage
                        : root.currentPage === "controls" ? controlsPage
                        : root.currentPage === "media" ? mediaPage
                        : root.currentPage === "workspaces" ? workspacesPage
                        : root.currentPage === "system" ? systemPage
                        : root.currentPage === "profile" ? profilePage
                        : dashboardPage
                }
            }
        }
    }

    Component {
        id: dashboardPage
        DashboardPage {
            width: pageLoader.width
            screenRef: root.screen
        }
    }

    Component {
        id: searchPage
        SearchPage {
            width: pageLoader.width
            open: root.open
        }
    }

    Component {
        id: calendarPage
        CalendarPage {
            width: pageLoader.width
        }
    }

    Component {
        id: controlsPage
        ControlsPage {
            width: pageLoader.width
        }
    }

    Component {
        id: mediaPage
        MediaPage {
            width: pageLoader.width
        }
    }

    Component {
        id: workspacesPage
        WorkspacesPage {
            width: pageLoader.width
            screenRef: root.screen
        }
    }

    Component {
        id: systemPage
        SystemPage {
            width: pageLoader.width
            screenRef: root.screen
        }
    }

    Component {
        id: profilePage
        ProfilePage {
            width: pageLoader.width
            screenRef: root.screen
        }
    }
}

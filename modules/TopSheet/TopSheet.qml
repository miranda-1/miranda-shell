import "../../components"
import "../../config"
import "../../services"
import "pages"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

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
    WlrLayershell.keyboardFocus: root.open && root.displayedPage === "search"
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    readonly property real screenWidth: root.screen && root.screen.width ? root.screen.width : 1440
    readonly property real screenHeight: root.screen && root.screen.height ? root.screen.height : 900
    // o compositor já desconta a zona exclusiva da EdgeLeft (e da topbar)
    // desta janela: x=0 aqui É a borda direita da barra. Somar Theme.barW de
    // novo criava um afastamento fantasma de 46px que nunca fechava.
    readonly property real interactiveLeft: 0
    readonly property real availableWidth: Math.max(720, root.screenWidth - root.interactiveLeft - 48)
    readonly property real panelWidth: Math.min(root.availableWidth, 1180)
    readonly property real panelHeight: Math.min(Math.max(root.screenHeight * 0.57, 480), 720)

    // nº de workspaces da tela — dimensiona o overview alt-tab.
    readonly property int workspaceCount: {
        const list = Hyprland.workspacesForScreen(root.screen);
        return (list && list.length > 0) ? list.length : Hyprland.workspaceList.length;
    }

    // largura por página: painéis bem mais estreitos (≈ -1/3 do antigo 1180,
    // e ainda menos nas páginas de pouco conteúdo)
    function pageWidthFor(pageId) {
        switch (pageId) {
        case "search":     return Math.min(root.availableWidth, 560);
        case "stats":
        case "power":      return Math.min(root.availableWidth, 460);
        case "keybinds":
        case "appearance":
        case "calendar":   return Math.min(root.availableWidth, 640);
        // workspaces = overview tipo alt-tab compacto e centralizado: a largura
        // acompanha o nº de colunas (cards ~320) em vez de esticar a tela toda.
        case "workspaces": {
            const cols = Math.max(1, Math.min(root.workspaceCount, 3));
            const card = 320;
            return Math.min(root.availableWidth, cols * card + (cols - 1) * Theme.gap + (Theme.pad + 2) * 2);
        }
        default:           return Math.min(root.availableWidth, 800);
        }
    }

    // x do painel aberto. Quase todas as páginas encaixam na EdgeLeft
    // (interactiveLeft = 0); workspaces abre centralizado na tela.
    function openXFor(pageId) {
        if (pageId === "workspaces")
            return Math.max(root.interactiveLeft, Math.round((root.width - root.pageWidthFor(pageId)) / 2));
        return root.interactiveLeft;
    }
    // página efetivamente renderizada. Na troca com o painel aberto, a aba
    // atual recolhe para dentro da barra, o conteúdo troca escondido e a nova
    // aba surge da esquerda na altura do seu botão.
    property string displayedPage: "dashboard"
    // false durante a troca: manda o painel de volta para dentro da barra
    property bool pageSettled: true

    readonly property bool searchDocked: root.displayedPage === "search"
    // painel mais estreito no modo busca: leitura de launcher, não de sheet
    readonly property real searchPanelWidth: Math.min(root.availableWidth, 760)

    // x do painel recolhido: inteiro atrás da EdgeLeft (a janela começa na
    // borda da barra, então x negativo é clipado — some "para dentro" dela)
    readonly property real hiddenX: -(sheet.width + 48)

    Component.onCompleted: root.displayedPage = root.currentPage

    onCurrentPageChanged: {
        // fechado/invisível: troca direto, sem coreografia
        if (!root.open || !root.panelVisible) {
            root.displayedPage = root.currentPage;
            return;
        }

        if (root.displayedPage === root.currentPage)
            return;

        // aberto: recolhe a aba atual; o timer troca o conteúdo quando ela
        // já está guardada e libera a nova a deslizar de volta
        root.pageSettled = false;
        pageSwapTimer.restart();
    }

    Timer {
        id: pageSwapTimer
        interval: Theme.tSlow + 40
        onTriggered: {
            root.displayedPage = root.currentPage;
            root.pageSettled = true;
        }
    }

    // topo do i-ésimo botão da coluna superior da EdgeLeft: topMargin (gap)
    // + i × (botão 40 + spacing 2). Workspaces fica após o divisor (10 + 2×2).
    function topButtonY(index) {
        return Theme.gap + index * 42;
    }

    // altura do painel encaixada no conteúdo da página (sem barriga vazia),
    // limitada à altura máxima de sheet. 105 = header + divisor + spacings.
    // respiro extra no fim de cada aba para o último elemento não colar na borda
    readonly property real bottomInset: Theme.pad + 8
    readonly property real sheetNeededHeight: (pageLoader.item ? pageLoader.item.implicitHeight : 0)
        + (root.searchDocked ? 0 : 105) + (Theme.pad + 2) * 2 + root.bottomInset
    // teto de altura: workspaces (overview alt-tab) usa quase a tela toda para
    // caber todos os cards sem rolar; as demais páginas ficam no panelHeight.
    readonly property real maxSheetHeight: root.displayedPage === "workspaces"
        ? Math.min(root.screenHeight * 0.86, root.screenHeight - 72)
        : root.panelHeight
    readonly property real sheetHeight: Math.max(240, Math.min(root.maxSheetHeight, root.sheetNeededHeight))

    // y do painel aberto: cada página nasce na linha do botão que a abriu
    function pageAnchorY() {
        const maxTop = Math.max(12, root.height - root.sheetHeight - 12);

        switch (root.displayedPage) {
        case "search":     return Math.min(root.topButtonY(1), maxTop);
        case "calendar":   return Math.min(root.topButtonY(2), maxTop);
        case "controls":   return Math.min(root.topButtonY(3), maxTop);
        case "media":      return Math.min(root.topButtonY(4), maxTop);
        case "keybinds":   return Math.min(root.topButtonY(5), maxTop);
        case "appearance": return Math.min(root.topButtonY(6), maxTop);
        case "workspaces": return Math.max(36, Math.round((root.height - root.sheetHeight) / 2));
        // base alinhada à base do respectivo botão da coluna inferior:
        // perfil termina em H-10; sistema logo acima, em H-52
        case "system":     return Math.max(12, root.height - 52 - root.sheetHeight);
        case "profile":    return Math.max(12, root.height - 10 - root.sheetHeight);
        case "power":      return Math.max(12, root.height - 10 - root.sheetHeight);
        case "stats":      return Math.max(12, root.height - 84 - root.sheetHeight);
        case "dashboard":
        default:           return Math.min(root.topButtonY(0), maxTop);
        }
    }
    readonly property bool panelVisible: root.open || sheet.x > root.hiddenX + 0.5
    readonly property string pageGlyph: root.metaForPage(root.displayedPage).glyph
    readonly property string pageTitle: root.metaForPage(root.displayedPage).title
    readonly property string pageSubtitle: root.metaForPage(root.displayedPage).subtitle
    readonly property var headerPills: root.pillsForPage(root.displayedPage)

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
            return { glyph: "", title: "Workspaces", subtitle: "Workspaces da tela com pré-visualização das janelas — clique para focar." };
        case "system":
            return { glyph: "", title: "Sistema", subtitle: "Sessão, uptime, bateria e leituras do ambiente atual sem polling externo." };
        case "profile":
            return { glyph: "", title: "Perfil e Energia", subtitle: "Identidade da sessão e ações futuras expostas apenas como placeholders." };
        case "keybinds":
            return { glyph: "", title: "Atalhos do teclado", subtitle: "Lista os atalhos do Hyprland lidos do seu keybindings.conf (somente leitura)." };
        case "appearance":
            return { glyph: "󰌹", title: "Aparência", subtitle: "Troque o tema e a imagem de fundo do HyDE direto pela shell." };
        case "power":
            return { glyph: "", title: "Energia e sessão", subtitle: "Bloquear, suspender, reiniciar, desligar ou iniciar no Windows — com confirmação." };
        case "stats":
            return { glyph: "", title: "Sistema ao vivo", subtitle: "CPU, memória e temperatura em tempo real." };
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
        case "keybinds":
        case "appearance":
        case "power":
        case "stats":
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
        // a aba desliza na horizontal: guardada atrás da barra (hiddenX) ou
        // encaixada nela (0). Abrir, fechar e trocar de página são sempre o
        // mesmo movimento de entrar/sair da EdgeLeft.
        x: root.open && root.pageSettled ? root.openXFor(root.displayedPage) : root.hiddenX
        // y e width não animam: só mudam com a aba escondida atrás da barra
        y: root.pageAnchorY()
        width: root.pageWidthFor(root.displayedPage)
        height: root.sheetHeight
        radius: Theme.radiusLg
        // quase opaco: sobre janelas (terminal/browser), translucidez alta
        // vira fantasma — o encaixe na barra fica por conta do x=0
        color: Qt.rgba(Theme.surfaceStrong.r, Theme.surfaceStrong.g, Theme.surfaceStrong.b, 0.995)
        border.color: Theme.strokeStrong
        clip: true
        visible: root.panelVisible

        Behavior on x { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutExpo } }
        // conteúdo dinâmico (listas expandindo) cresce o painel suavemente
        Behavior on height { NumberAnimation { duration: Theme.tBase; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.pad + 2
            spacing: Theme.pad

            // no modo busca o header sai: a página começa direto no campo,
            // alinhado ao braço que nasce na lupa da EdgeLeft
            TopSheetHeader {
                visible: !root.searchDocked
                width: parent.width
                glyph: root.pageGlyph
                title: root.pageTitle
                subtitle: root.pageSubtitle
                pills: root.headerPills
                showCloseButton: true
                onCloseRequested: root.requestClose()
            }

            Rectangle {
                visible: !root.searchDocked
                width: parent.width
                height: 1
                color: Theme.stroke
            }

            Flickable {
                id: scroll
                width: parent.width
                height: root.searchDocked ? parent.height : parent.height - 105
                clip: true
                contentWidth: width
                contentHeight: (pageLoader.item ? pageLoader.item.implicitHeight : 0) + root.bottomInset
                boundsBehavior: Flickable.StopAtBounds

                // barra de rolagem: só para páginas com conteúdo longo
                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    readonly property bool pageNeedsScroll: ["keybinds", "dashboard", "workspaces", "system", "profile"].indexOf(root.displayedPage) >= 0
                    policy: pageNeedsScroll && scroll.contentHeight > scroll.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    width: 10
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: vbar.pressed ? Theme.accentActive : Theme.textFaint
                        opacity: vbar.pressed || vbar.hovered ? 0.95 : 0.55

                        Behavior on color { ColorAnimation { duration: Theme.tFast } }
                    }
                }

                Loader {
                    id: pageLoader
                    width: scroll.width
                    sourceComponent: root.displayedPage === "search" ? searchPage
                        : root.displayedPage === "calendar" ? calendarPage
                        : root.displayedPage === "controls" ? controlsPage
                        : root.displayedPage === "media" ? mediaPage
                        : root.displayedPage === "workspaces" ? workspacesPage
                        : root.displayedPage === "system" ? systemPage
                        : root.displayedPage === "profile" ? profilePage
                        : root.displayedPage === "keybinds" ? keybindsPage
                        : root.displayedPage === "appearance" ? appearancePage
                        : root.displayedPage === "power" ? powerPage
                        : root.displayedPage === "stats" ? statsPage
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
            onRequestClose: root.requestClose()
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
            onRequestClose: root.requestClose()
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

    Component {
        id: keybindsPage
        KeybindsPage {
            width: pageLoader.width
        }
    }

    Component {
        id: appearancePage
        AppearancePage {
            width: pageLoader.width
        }
    }

    Component {
        id: powerPage
        PowerPage {
            width: pageLoader.width
        }
    }

    Component {
        id: statsPage
        StatsPage {
            width: pageLoader.width
        }
    }
}

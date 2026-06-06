pragma Singleton

import Quickshell
import QtQuick

// Tokens visuais centrais — tema claro "rosé / ink" derivado dos prints de
// referência (assets/references/). Estruturado para, na Fase 4, derivar do
// wallpaper e suportar um esquema dark via `isDark`.
Singleton {
    // ---- esquema ativo ----
    readonly property bool isDark: false

    // ---- superfícies (translúcidas sobre o wallpaper) ----
    readonly property color surface:      Qt.rgba(0.965, 0.925, 0.905, 0.82) // painel/drawer
    readonly property color card:         Qt.rgba(0.976, 0.945, 0.929, 0.92) // card
    readonly property color cardHover:    Qt.rgba(0.988, 0.961, 0.949, 0.96) // card em hover
    readonly property color bar:          Qt.rgba(0.965, 0.925, 0.905, 0.85) // barra esquerda
    // painel "sólido focado": quase opaco, para overlays que se sobrepõem a
    // JANELAS (não só ao wallpaper) — sem blur real, a translucidez alta virava
    // fantasma sobre terminal/browser. Usado no Launcher.
    readonly property color surfaceStrong: Qt.rgba(0.972, 0.940, 0.922, 0.985)

    // ---- acento clay / rosé ----
    readonly property color accent:       "#b0604a"   // terracota principal
    readonly property color accentActive: "#a8553f"   // fill ativo (círculo)
    readonly property color accentSoft:   "#e8c5b8"   // hover sutil / trilha de anel
    readonly property color accentTrack:  "#f0dcd4"   // fundo de progresso

    // ---- texto ----
    readonly property color text:         "#3a322e"
    readonly property color textDim:      "#8f827a"
    readonly property color textFaint:    "#bdb0a8"
    readonly property color textOnAccent: "#fdf6f2"   // texto/ícone sobre fill clay

    // ---- separação (quase sem stroke; a sombra é a borda) ----
    readonly property color stroke:       Qt.rgba(0, 0, 0, 0.06)
    readonly property color strokeStrong: Qt.rgba(0, 0, 0, 0.12)  // contorno mais nítido p/ separar de janelas
    readonly property color shadow:       Qt.rgba(0, 0, 0, 0.16)
    readonly property real  shadowBlur:   0.8   // 0..1 (MultiEffect)
    readonly property int   shadowY:      6

    // ---- forma ----
    readonly property int   radius:       18
    readonly property int   radiusSm:     12
    readonly property int   radiusPill:   999
    readonly property int   screenRound:  22    // raio generoso p/ peças orgânicas ancoradas na borda

    // ---- puxadores minimalistas (topo / direita / base) ----
    readonly property int   gripLen:      52
    readonly property int   gripThickness: 3
    readonly property color gripColor:    Qt.rgba(0.952, 0.914, 0.894, 0.98)
    readonly property color gripHover:    Qt.rgba(0.914, 0.835, 0.798, 0.98)

    // ---- espaçamento ----
    readonly property int   gap:          10
    readonly property int   pad:          16

    // ---- dimensões das bordas ----
    readonly property int   barW:         46    // barra esquerda fina
    readonly property int   sliver:       6      // borda de hover (topo/direita)
    readonly property int   iconSize:     19
    readonly property int   tooltipReserve: 280  // espaço transparente p/ tooltips

    // ---- tipografia ----
    readonly property string iconFont:    "JetBrainsMono Nerd Font"

    // ---- timing das animações (sensação "viva") ----
    // Só durações aqui (ints). O easing vai direto na animação:
    //   easing.type: Easing.OutCubic   (geral)
    //   easing.type: Easing.OutExpo    (drawer / launcher)
    readonly property int   tFast:        120
    readonly property int   tBase:        240
    readonly property int   tSlow:        360

    // atraso antes de um overlay abrir por hover — confirma intenção e evita
    // abertura acidental ao só passar o mouse na borda.
    readonly property int   tHoverOpen:   280
    // atraso antes de fechar — segura o painel enquanto o mouse cruza o corredor
    // entre puxador e conteúdo, evitando fechamento prematuro.
    readonly property int   tHoverClose:  220
}

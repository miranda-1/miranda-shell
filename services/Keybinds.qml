pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Atalhos do Hyprland — SOMENTE LEITURA do keybindings.conf via FileView.
// Faz parse best-effort de `bind(d) = MODS, KEY, [$d descrição,] dispatcher,...`,
// traduz a descrição para pt-BR e agrupa por tópico para facilitar a busca.
Singleton {
    id: root

    FileView {
        id: kb
        path: Quickshell.env("HOME") + "/.config/hypr/keybindings.conf"
        preload: true
        blockLoading: true
        watchChanges: true
    }

    // ordem de exibição dos tópicos
    readonly property var topicOrder: [
        "Janelas", "Áreas de trabalho", "Aplicativos", "Busca e lançadores",
        "Mídia e teclas", "Capturas de tela", "Aparência", "Sistema e sessão", "Outros"
    ]

    // dicionário de tradução (chave = descrição em inglês normalizada/minúscula)
    readonly property var dict: ({
        "application finder": "Buscar aplicativos",
        "change active group backwards": "Grupo ativo: anterior",
        "change active group forwards": "Grupo ativo: próximo",
        "change active workspace backwards": "Área anterior",
        "change active workspace forwards": "Próxima área",
        "clipboard": "Área de transferência",
        "clipboard manager": "Gerenciador de transferência",
        "close focused window": "Fechar janela em foco",
        "color picker": "Seletor de cores",
        "cycle focus": "Alternar foco",
        "decrease brightness": "Diminuir brilho",
        "decrease volume": "Diminuir volume",
        "dropdown terminal": "Terminal suspenso",
        "emoji picker": "Seletor de emoji",
        "file explorer": "Gerenciador de arquivos",
        "file finder": "Buscar arquivos",
        "focus down": "Focar abaixo",
        "focus left": "Focar à esquerda",
        "focus right": "Focar à direita",
        "focus up": "Focar acima",
        "freeze and snip screen": "Congelar e recortar tela",
        "game mode": "Modo jogo",
        "glyph picker": "Seletor de glifos",
        "hold to move window": "Segurar para mover janela",
        "hold to resize window": "Segurar para redimensionar",
        "increase brightness": "Aumentar brilho",
        "increase volume": "Aumentar volume",
        "keybindings hint": "Dica de atalhos",
        "kill hyprland session": "Encerrar sessão do Hyprland",
        "lock screen": "Bloquear tela",
        "logout menu": "Menu de encerramento",
        "move to scratchpad": "Mover para scratchpad",
        "move to scratchpad (silent)": "Mover para scratchpad (silencioso)",
        "move window to next relative workspace": "Mover janela p/ próxima área",
        "move window to previous relative workspace": "Mover janela p/ área anterior",
        "navigate to the nearest empty workspace": "Ir para área vazia mais próxima",
        "next global wallpaper": "Próximo wallpaper",
        "next media": "Próxima mídia",
        "next waybar layout": "Próximo layout da waybar",
        "next workspace": "Próxima área",
        "open game launcher": "Abrir launcher de jogos",
        "pause media": "Pausar mídia",
        "play media": "Tocar mídia",
        "previous global wallpaper": "Wallpaper anterior",
        "previous media": "Mídia anterior",
        "previous waybar layout": "Layout anterior da waybar",
        "previous workspace": "Área anterior",
        "print all monitors": "Capturar todos os monitores",
        "print monitor": "Capturar monitor",
        "resize window down": "Redimensionar p/ baixo",
        "resize window left": "Redimensionar p/ esquerda",
        "resize window right": "Redimensionar p/ direita",
        "resize window up": "Redimensionar p/ cima",
        "select a global wallpaper": "Escolher wallpaper",
        "select animations": "Escolher animações",
        "select a theme": "Escolher tema",
        "select hyprlock layout": "Escolher layout do hyprlock",
        "select rofi launcher": "Escolher launcher do rofi",
        "snip screen": "Recortar tela",
        "system monitor": "Monitor do sistema",
        "terminal emulator": "Emulador de terminal",
        "text editor": "Editor de texto",
        "toggle floating": "Alternar flutuante",
        "toggle fullscreen": "Alternar tela cheia",
        "toggle group": "Alternar grupo",
        "toggle keyboard layout": "Alternar layout do teclado",
        "toggle mute output": "Alternar mudo (saída)",
        "toggle mute/unmute for active-window": "Alternar mudo da janela ativa",
        "toggle pin on focused window": "Fixar janela em foco",
        "toggle scratchpad": "Alternar scratchpad",
        "toggle split": "Alternar divisão",
        "toggle waybar and reload config": "Alternar waybar e recarregar",
        "un/mute microphone": "Alternar mudo do microfone",
        "wallbash mode selector": "Seletor de modo wallbash",
        "web browser": "Navegador",
        "window switcher": "Alternador de janelas"
    })

    function _norm(s) {
        return s.replace(/\$d/gi, "").replace(/\s+/g, " ").trim();
    }

    function _translate(raw) {
        const n = root._norm(raw);
        const low = n.toLowerCase();

        let m = low.match(/^move to workspace (\d+) \(silent\)$/);
        if (m) return "Mover para área " + m[1] + " (silencioso)";
        m = low.match(/^move to workspace (\d+)$/);
        if (m) return "Mover para área " + m[1];
        m = low.match(/^navigate to workspace (\d+)$/);
        if (m) return "Ir para área " + m[1];

        if (root.dict[low])
            return root.dict[low];
        return n.length > 0 ? n : "(sem descrição)";
    }

    function _topic(raw) {
        // categoriza pela DESCRIÇÃO apenas (a ação tem variáveis como
        // $KILLACTIVE que poluem o match, ex.: "kill")
        const s = root._norm(raw).toLowerCase();
        if (/wallpaper|theme|animations|hyprlock|wallbash|waybar layout/.test(s)) return "Aparência";
        if (/screenshot|snip|print|grim|freeze/.test(s)) return "Capturas de tela";
        if (/volume|mute|microphone|brightness|media|playerctl|mpris/.test(s)) return "Mídia e teclas";
        if (/workspace|scratchpad/.test(s)) return "Áreas de trabalho";
        if (/rofi|finder|switcher|emoji|glyph|clipboard|color picker|keybindings hint/.test(s)) return "Busca e lançadores";
        if (/terminal|explorer|editor|browser|game|system monitor/.test(s)) return "Aplicativos";
        if (/lock|logout|kill|reload|session|exit|suspend|keyboard layout|waybar/.test(s)) return "Sistema e sessão";
        if (/window|float|fullscreen|pin|split|group|focus|resize|move|swap|center/.test(s)) return "Janelas";
        return "Outros";
    }

    function _mods(s) {
        const cleaned = s.replace(/\$mainMod/gi, "Super").replace(/\bSUPER\b/g, "Super").trim();
        const parts = cleaned.split(/\s+/).filter(function(p) { return p.length > 0; });
        return parts.join(" + ");
    }

    // lista crua de atalhos: { combo, desc, topic }
    readonly property var binds: {
        const t = kb.text();
        if (!t)
            return [];

        const out = [];
        const lines = t.split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.indexOf("bind") !== 0)
                continue;

            const eq = line.indexOf("=");
            if (eq < 0)
                continue;

            const head = line.slice(0, eq);
            const hasDesc = head.indexOf("bindd") === 0;
            const parts = line.slice(eq + 1).split(",").map(function(p) { return p.trim(); });
            if (parts.length < 2)
                continue;

            const mods = root._mods(parts[0]);
            const key = parts[1];
            let rawDesc = "";
            let action = "";
            if (hasDesc && parts.length >= 3) {
                rawDesc = parts[2];
                action = parts.slice(3).join(" ");
            } else {
                rawDesc = parts.slice(2).join(" ");
                action = rawDesc;
            }

            const combo = (mods.length > 0 ? mods + " + " : "") + key;
            out.push({
                combo: combo,
                desc: root._translate(rawDesc),
                topic: root._topic(rawDesc)
            });
        }

        return out;
    }

    // atalhos agrupados por tópico, na ordem de topicOrder
    readonly property var groups: {
        const buckets = {};
        for (let i = 0; i < root.binds.length; i++) {
            const b = root.binds[i];
            if (!buckets[b.topic])
                buckets[b.topic] = [];
            buckets[b.topic].push(b);
        }

        const result = [];
        for (let j = 0; j < root.topicOrder.length; j++) {
            const title = root.topicOrder[j];
            if (buckets[title] && buckets[title].length > 0)
                result.push({ title: title, items: buckets[title] });
        }
        return result;
    }
}

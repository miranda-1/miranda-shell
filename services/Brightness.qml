pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Serviço de brilho da TELA INTERNA do notebook.
// Decisão do usuário (2026-06-13): controlar SOMENTE a tela interna; o monitor
// externo (que exigiria DDC/ddcutil) fica de fora de propósito.
//
// ATENÇÃO — exceção de política: este é o ÚNICO ponto do projeto que usa um
// processo externo. A LEITURA do brilho é via sysfs (FileView). A ESCRITA usa
// `brightnessctl`, que ajusta o backlight via systemd-logind (sem root) — o
// sysfs é root-only, então não há como escrever direto. Comando fixo, sem
// interpolação de shell, escopado ao backlight interno detectado.
//
// NOTA: arquivos de /sys NÃO disparam inotify de forma confiável, então
// `FileView.watchChanges` não funciona aqui. Em vez disso: o slider usa um
// valor "ao vivo" (`displayValue`) que atualiza na hora ao arrastar, e um Timer
// recarrega o sysfs periodicamente para refletir mudanças externas (teclas de
// brilho).
Singleton {
    id: root

    // backlight interno detectado nesta máquina
    readonly property string device: "nvidia_wmi_ec_backlight"
    readonly property string basePath: "/sys/class/backlight/" + root.device

    FileView {
        id: curFile
        path: root.basePath + "/brightness"
        preload: true
        blockLoading: true
    }

    FileView {
        id: maxFile
        path: root.basePath + "/max_brightness"
        preload: true
        blockLoading: true
    }

    readonly property int rawMax: {
        const t = maxFile.text();
        const n = t ? parseInt(t.trim()) : 0;
        return isNaN(n) ? 0 : n;
    }

    readonly property int rawValue: {
        const t = curFile.text();
        const n = t ? parseInt(t.trim()) : 0;
        return isNaN(n) ? 0 : n;
    }

    readonly property bool available: root.rawMax > 0

    // fração 0–1 lida do sysfs no momento
    readonly property real sysfsValue: root.available
        ? Math.max(0, Math.min(1, root.rawValue / root.rawMax))
        : 0

    // valor exibido pelo slider (fonte de verdade da UI)
    property real displayValue: 0

    readonly property real value: root.available
        ? Math.max(0, Math.min(1, root.displayValue))
        : 0

    Component.onCompleted: root.displayValue = root.sysfsValue

    // recarrega o sysfs de tempos em tempos para pegar mudanças externas
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: curFile.reload()
    }

    // adota o valor do sysfs só quando ele diverge de forma relevante do que
    // mostramos (ex.: teclas de brilho). Diferenças pequenas (arredondamento do
    // nosso próprio comando) são ignoradas para o slider não "brigar" sozinho.
    onSysfsValueChanged: {
        if (root.available && Math.abs(root.sysfsValue - root.displayValue) > 0.06)
            root.displayValue = root.sysfsValue;
    }

    // define o brilho (fração 0–1). Piso de 2% para nunca apagar a tela.
    function setPercent(frac) {
        if (!root.available)
            return false;

        const v = Math.max(0.02, Math.min(1, frac));
        root.displayValue = v;   // feedback imediato no slider
        const pct = Math.round(v * 100);
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "set", pct + "%"]);
        return true;
    }
}

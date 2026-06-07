pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// Serviço read-only de bateria (Fase 5). Fonte: Quickshell UPower (nativo,
// evented — sem polling, sem comando externo). Apenas LEITURA: não controla
// carga, não altera perfil de energia, não escreve nada. Em máquinas sem
// bateria de laptop, `available` é false e a UI pode se esconder.
Singleton {
    id: root

    // device agregado do UPower (a "bateria de exibição" do sistema)
    readonly property var dev: UPower.displayDevice

    // só consideramos quando é realmente uma bateria de laptop e está pronta
    readonly property bool available: !!root.dev && root.dev.ready && root.dev.isLaptopBattery

    // percentual 0–100 (UPower expõe percentage como fração 0–1)
    readonly property int percent: root.available ? Math.round(root.dev.percentage * 100) : -1
    readonly property string percentText: root.available ? root.percent + "%" : "--"

    // estado de carga (read-only)
    readonly property bool onBattery: UPower.onBattery
    readonly property bool charging: root.available
        && (root.dev.state === UPowerDeviceState.Charging
            || root.dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: root.available && root.dev.state === UPowerDeviceState.FullyCharged

    // tempo restante (segundos → "1h 23m" / "23m"); vazio quando indisponível
    function _fmt(sec) {
        if (!sec || sec <= 0)
            return "";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return h > 0 ? (h + "h " + m + "m") : (m + "m");
    }
    readonly property string timeText: {
        if (!root.available)
            return "";
        return root.charging ? root._fmt(root.dev.timeToFull) : root._fmt(root.dev.timeToEmpty);
    }

    // rótulo curto e seguro para a UI: "84%", "84% (carregando)", "100% (cheia)"
    readonly property string statusText: {
        if (!root.available)
            return "";
        if (root.full)
            return root.percent + "% (cheia)";
        if (root.charging)
            return root.percent + "% (carregando)";
        return root.percent + "%";
    }
}
